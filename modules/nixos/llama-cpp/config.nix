{ lib, config, pkgs, outputs, ... }:

let
  cfg = config.mine.llama-cpp;
  llamaCfg = config.services.llama-cpp;
  # Custom flake-output package: charlie12345/rocmfp4-llama fork compiled with
  # ROCmFP4 quant support for gfx1151 (Strix Halo). Built per-system from
  # pkgs/rocmfp4-llama/package.nix and exposed at outputs.packages.
  rocmfp4Package = outputs.packages.${pkgs.stdenv.hostPlatform.system}.rocmfp4-llama;
  selectedPackage =
    if cfg.rocmfp4 then
      rocmfp4Package
    else if cfg.cuda then
      pkgs.llama-cpp.override { cudaSupport = true; }
    else if cfg.rocm then
      pkgs.llama-cpp-rocm
    else if cfg.vulkan then
      pkgs.llama-cpp-vulkan
    else
      pkgs.llama-cpp;
in
{
  # Mutual-exclusion assertions for GPU backend options. Only one of
  # cuda/rocm/vulkan/rocmfp4 may be true at a time. rocmfp4 is mutex with
  # rocm and vulkan because the rocmfp4 binary already contains both HIP
  # and Vulkan backends; the dual setting would be ambiguous.
  assertions = [
    {
      assertion =
        (lib.count (x: x) [ cfg.cuda cfg.rocm cfg.vulkan cfg.rocmfp4 ]) <= 1;
      message = ''
        mine.llama-cpp: only one of `cuda`, `rocm`, `vulkan`, `rocmfp4` may
        be enabled at a time.
      '';
    }
    {
      assertion = cfg.modelsPreset == null;
      message = ''
        mine.llama-cpp.modelsPreset is no longer supported by upstream
        services.llama-cpp. Use mine.llama-cpp.modelFile or HuggingFace
        auto-download options instead.
      '';
    }
    {
      assertion = cfg.kvCacheQuant == "f16" || cfg.flashAttn != "off";
      message = ''
        mine.llama-cpp: quantized KV cache requires flash attention in current
        llama.cpp because this module sets both --cache-type-k and
        --cache-type-v. Use kvCacheQuant = "f16" when flashAttn = "off".
      '';
    }
    {
      assertion = !cfg.cuda || (config.nixpkgs.config.cudaSupport or false);
      message = ''
        mine.llama-cpp.cuda = true requires nixpkgs.config.cudaSupport = true
        so pkgs.llama-cpp is built with the CUDA backend.
      '';
    }
  ];

  services.llama-cpp = {
    enable = true;

    # GPU backend selection. The default nixpkgs llama-cpp is CPU-only.
    #   - llama-cpp + CUDA: libggml-cuda.so for NVIDIA GPUs.
    #   - llama-cpp-rocm:   libggml-hip.so for RDNA/CDNA via ROCm/HIP.
    #   - llama-cpp-vulkan: libggml-vulkan.so for any Vulkan-capable GPU.
    #   - rocmfp4Package:   custom fork with ROCmFP4 quants + dual HIP/Vulkan.
    package = selectedPackage;

    settings = {
      inherit (cfg) host port;
      # GPU offload: push all transformer layers to VRAM.
      n-gpu-layers = cfg.gpuLayers;
      # Flash attention: confirmed real gains on RDNA 4 (GFX1201 / KHR_coopmat):
      # +4-11% prefill throughput, +4% generation throughput vs no-FA.
      # Configurable because some NVIDIA driver/GSP paths can crash under FA load.
      flash-attn = cfg.flashAttn;
      # KV cache quantization: symmetric type required for fused flash attention
      # kernel. q8_0 halves VRAM vs f16 with near-zero quality loss.
      cache-type-k = cfg.kvCacheQuant;
      cache-type-v = cfg.kvCacheQuant;
      # Context window — override via contextSize option.
      ctx-size = cfg.contextSize;
      # Prompt-processing batch sizes. Larger values improve prefill throughput
      # but increase CUDA compute-buffer pressure.
      batch-size = cfg.batchSize;
      ubatch-size = cfg.ubatchSize;
      # High process priority — GPU is dedicated to LLM inference.
      prio = 2;
      # Disk-backed prompt cache size in MiB. See `cacheRamMiB` option doc
      # for the model-architecture-specific guidance. tl;dr: 0 for hybrid
      # models (Qwen3.6 etc.), 8192 (default) for standard transformers.
      cache-ram = cfg.cacheRamMiB;
      # Single parallel slot — all VRAM to one session.
      parallel = 1;
    }
    // lib.optionalAttrs (cfg.modelFile != null) { model = cfg.modelFile; }
    // lib.optionalAttrs (cfg.modelsDir != null) { models-dir = cfg.modelsDir; }
    // lib.optionalAttrs (cfg.hfRepo != null) { hf-repo = cfg.hfRepo; }
    // lib.optionalAttrs (cfg.hfFile != null) { hf-file = cfg.hfFile; }
    // lib.optionalAttrs (cfg.alias != null) { inherit (cfg) alias; };
    # Keep the host firewall closed. Tailscale access is allowed via tailscale0.
    openFirewall = false;
  };

  # GPU-specific service hardening overrides.
  # CUDA (PTX JIT) and ROCm (HIP JIT) require W+X memory pages at runtime.
  # The upstream nixpkgs unit sets DynamicUser=true,
  # MemoryDenyWriteExecute=true, and PrivateUsers=true. DynamicUser also makes
  # systemd relocate StateDirectory/CacheDirectory below private directories,
  # which conflicts with Incus bind mounts at /var/lib/llama-cpp and
  # /var/cache/llama-cpp. Vulkan does not JIT in the same way as CUDA/ROCm, but
  # the same sandbox blocks /dev/dri access and breaks render/video group
  # propagation. Apply these overrides for all GPU backends including the
  # rocmfp4 fork (which is HIP-based + Vulkan).
  systemd.services.llama-cpp = lib.mkMerge [
    {
      unitConfig = {
        # GPU init failures should not create an endless coredump/probe loop.
        StartLimitBurst = 3;
        StartLimitIntervalSec = "30min";
      };
      # Upstream removed services.llama-cpp.extraFlags in favor of settings,
      # but llama-server still has flags that do not round-trip through
      # lib.cli.toCommandLine, notably rocmfp4's single-dash "-dev".
      serviceConfig.ExecStart = lib.mkForce (toString [
        (lib.getExe' llamaCfg.package "llama-server")
        (lib.cli.toCommandLine
          (optionName: {
            option = if builtins.stringLength optionName > 1 then "--${optionName}" else "-${optionName}";
            sep = " ";
            explicitBool = false;
            formatArg = lib.generators.mkValueStringDefault { };
          })
          llamaCfg.settings)
        cfg.extraFlags
      ]);
    }
    (lib.mkIf (cfg.rocm || cfg.cuda || cfg.vulkan || cfg.rocmfp4) {
      # network.target is not sufficient for internet connectivity — the upstream
      # unit only sets After=network.target. HuggingFace auto-download fails at
      # boot unless we wait for an actual routable connection.
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        DynamicUser = lib.mkForce false;
        MemoryDenyWriteExecute = lib.mkForce false;
        PrivateUsers = lib.mkForce false;
        # GPU compute requires access to /dev/kfd (ROCm) or /dev/nvidia* (CUDA) and
        # /dev/dri/renderD* (all backends, including Vulkan). The DynamicUser sandbox
        # needs these group memberships.
        SupplementaryGroups = [ "render" "video" ];
      };

      environment = lib.mkMerge [
        (lib.optionalAttrs cfg.cuda {
          # Incus' NVIDIA runtime mounts host driver libraries under /usr/lib64.
          # llama.cpp's CUDA backend dlopens libcuda.so.1 from there at runtime.
          LD_LIBRARY_PATH = "/usr/lib64:/run/opengl-driver/lib";
          NVIDIA_VISIBLE_DEVICES = "all";
        })
        # Vulkan path env (also applied for rocmfp4 because the dual-backend
        # binary embeds the Vulkan code path and benefits from the Mesa cache
        # even when the runtime backend is ROCm0).
        (lib.optionalAttrs (cfg.vulkan || cfg.rocmfp4) {
          # Persist the Mesa pipeline (SPIR-V → ISA) shader cache across service
          # restarts. Without this, the first prompt after a fresh service start
          # spends ~20s recompiling shaders for every unique compute shape —
          # measured cold pp ≈ 1 tok/s vs warm ≈ 145 tok/s on Qwen3.6-27B Q6_K.
          # systemd's CacheDirectory provides /var/cache/llama-cpp (resolves to
          # /var/cache/private/llama-cpp under DynamicUser=true); the incus
          # profile bind-mounts that to host-side storage so the cache survives
          # container relaunches as well as service restarts.
          MESA_SHADER_CACHE_DIR = "/var/cache/llama-cpp/mesa-shaders";
          # Prevent RADV from spilling GPU buffer allocations into GTT under
          # perceived memory pressure. On discrete RDNA 4 (R9700) this produces
          # a measured 4.5× decode speedup by avoiding PCIe round-trips.
          # On Strix Halo unified memory (goldenball) VRAM and GTT share the
          # same physical LPDDR5X, so there is no PCIe penalty — but the flag
          # still affects how RADV manages memory pressure during heavy MTP
          # inference bursts. Removing it coincided with increased display
          # engine flip_done timeouts after inference; restored as a mitigation.
          RADV_PERFTEST = "nogttspill";
        })
        (lib.optionalAttrs (cfg.rocm && cfg.rocmVisibleDevices != null) {
          # Restrict ROCm to a specific GPU by index. Use when multiple AMD GPUs
          # are present and inference must land on a particular one (e.g. an iGPU
          # + discrete GPU laptop).
          ROCR_VISIBLE_DEVICES = cfg.rocmVisibleDevices;
        })
        # ROCmFP4 fork-specific env vars (per upstream STRIX-HALO-QUICKSTART.md).
        (lib.optionalAttrs cfg.rocmfp4 {
          # Force gfx11.5.1 ISA selection on Strix Halo. The chip reports as
          # gfx1151 but ROCm 7.x device libraries are keyed on gfx11.5.1; this
          # override is required for the HIP runtime to pick the correct
          # bitcode at JIT time. Removing it crashes with "no HIP GPUs are
          # available" or generates wrong-arch kernels.
          HSA_OVERRIDE_GFX_VERSION = "11.5.1";
          # Allow HIP allocations to span unified-memory pages (Strix Halo
          # CPU+GPU share LPDDR5X). Without this, HIP rejects allocations
          # larger than the GTT carve-out.
          GGML_HIP_ENABLE_UNIFIED_MEMORY = "1";
        })
      ];
    })
  ];

  systemd.services.llama-cpp-nvidia-runtime-libs = lib.mkIf cfg.cuda {
    description = "Prepare NVIDIA runtime library symlinks for llama.cpp";
    before = [ "llama-cpp.service" ];
    requiredBy = [ "llama-cpp.service" ];
    serviceConfig = {
      RemainAfterExit = true;
      Type = "oneshot";
    };
    script = ''
      link_latest() {
        dir="$1"
        soname="$2"

        if [ ! -d "$dir" ] || [ -e "$dir/$soname.1" ]; then
          return
        fi

        target="$(${pkgs.findutils}/bin/find "$dir" -maxdepth 1 -type f -name "$soname.*" ! -name '*debug*' | ${pkgs.coreutils}/bin/sort -V | ${pkgs.coreutils}/bin/tail -n 1)"
        if [ -n "$target" ]; then
          ${pkgs.coreutils}/bin/ln -s "''${target##*/}" "$dir/$soname.1"
        fi
      }

      for dir in /usr/lib64 /usr/lib; do
        link_latest "$dir" libcuda.so
        link_latest "$dir" libnvidia-ml.so
      done
    '';
  };

  # Allow members of the wheel group to start/stop llama-cpp without a
  # password prompt. Used by the llama-cpp-toggle script below.
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        (action.id === "org.freedesktop.systemd1.manage-units" ||
         action.id === "org.freedesktop.systemd1.manage-unit-files") &&
        action.lookup("unit") === "llama-cpp.service" &&
        subject.isInGroup("wheel")
      ) {
        return polkit.Result.YES;
      }
    });
  '';

  # Toggle script + .desktop entry for the KDE app launcher.
  # The script is also the executable called by the SNI tray daemon
  # (mine.home.kde-apps.llamaCppLauncher) for manual CLI use.
  # Use mine.home.kde-apps.llamaCppLauncher = true on a host to get a
  # proper system-tray icon (SNI daemon) alongside wifi/bluetooth/volume.
  environment.systemPackages =
    let
      toggleScript = pkgs.writeShellScriptBin "llama-cpp-toggle" ''
        if systemctl is-active --quiet llama-cpp.service; then
          systemctl stop llama-cpp.service
          notify-send --urgency=normal --icon=media-playback-stop \
            "llama-cpp" "Service stopped — GPU RAM freed"
        else
          systemctl start llama-cpp.service
          notify-send --urgency=normal --icon=media-playback-start \
            "llama-cpp" "Service starting — model loading (~15s)"
        fi
      '';
      desktopEntry = pkgs.makeDesktopItem {
        name = "llama-cpp-toggle";
        desktopName = "LLaMA Server Toggle";
        comment = "Start or stop the local llama-cpp inference server";
        exec = "${toggleScript}/bin/llama-cpp-toggle";
        # preferences-devices-cpu: chip/CPU icon — visually distinct in the panel,
        # appropriate for "local inference engine running on this hardware".
        icon = "preferences-devices-cpu";
        categories = [ "Utility" "Science" ];
        keywords = [ "llama" "ai" "llm" "inference" ];
      };
    in
    [ toggleScript desktopEntry ];
}
