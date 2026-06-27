{ lib, config, pkgs, outputs, ... }:
let
  cfg = config.mine.llama-cpp;
  llamaCfg = config.services.llama-cpp;
  # Custom flake-output package: charlie12345/rocmfp4-llama fork compiled with
  # ROCmFP4 quant support for gfx1151 (Strix Halo). Built per-system from
  # pkgs/rocmfp4-llama/package.nix and exposed at outputs.packages.
  rocmfp4Package = outputs.packages.${pkgs.stdenv.hostPlatform.system}.rocmfp4-llama;
  selectedPackage =
    if cfg.rocmfp4 then rocmfp4Package
    else if cfg.rocm then pkgs.llama-cpp-rocm
    else if cfg.vulkan then pkgs.llama-cpp-vulkan
    else pkgs.llama-cpp;
in
{

  options.mine.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp inference server (llama-server)";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for llama-server to listen on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for llama-server to listen on.";
    };

    modelFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to a GGUF model file to load eagerly at startup.
        When set, passed as --model to llama-server. The model is loaded
        immediately on service start, eliminating cold-start latency on
        the first request. Use this for single-model dedicated setups.
        Mutually exclusive with modelsPreset router mode.
      '';
      example = "/var/lib/llama-cpp/models/Qwen3-14B-Q6_K.gguf";
    };

    alias = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Model name advertised by llama-server at /v1/models. When unset,
        llama-server defaults to the basename of `modelFile` or to `hfRepo`
        when auto-downloading. Set this when you need a stable, predictable
        model ID for clients (e.g. opencode provider keys) that doesn't change
        when the underlying GGUF file is renamed or replaced.

        Passed as --alias to llama-server.
      '';
      example = "qwen3.6-35b-a3b-mtp-rocmfp4-lean";
    };

    hfRepo = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        HuggingFace repository to auto-download the model from if modelFile
        does not exist on disk yet. Combined with hfFile. Once downloaded,
        the file is cached at modelsDir and loaded from there on subsequent starts.
      '';
      example = "unsloth/Qwen3-14B-GGUF";
    };

    hfFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        HuggingFace filename to download. Used with hfRepo.
      '';
      example = "Qwen3-14B-Q6_K.gguf";
    };

    modelsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Directory where GGUF model files are stored. Used as the storage
        location for HuggingFace auto-downloads. All models accumulate here
        across container rebuilds via the persistent bind-mount.
        When set, passed as --models-dir to llama-server.
      '';
    };

    modelsPreset = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf (lib.types.attrsOf lib.types.str));
      default = null;
      description = ''
        Declarative model preset configuration for the llama-server router mode.
        Each key is a model alias, with attrs for hf-repo, hf-file, etc.
        Models are loaded on-demand (cold start on first request per model).
        Use modelFile instead for eager single-model loading.
      '';
      example = lib.literalExpression ''
        {
          "qwen3-14b" = {
            hf-repo = "unsloth/Qwen3-14B-GGUF";
            hf-file = "Qwen3-14B-Q6_K.gguf";
            alias = "qwen3-14b";
          };
        }
      '';
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 32768;
      description = ''
        Context window size in tokens passed as -c to llama-server.
        With q8_0 KV cache quantization, 32K is a reliable default for 16 GiB
        cards (e.g. RTX 5060 Ti) running 24B-class models at Q4. Increase for
        smaller models that leave more VRAM headroom.
      '';
    };

    kvCacheQuant = lib.mkOption {
      type = lib.types.enum [ "f16" "q8_0" "q4_0" ];
      default = "q8_0";
      description = ''
        Quantization type for the KV cache (applied to both K and V).
        Must be symmetric (same type for K and V) to use the fused flash
        attention kernel. q8_0 halves VRAM vs f16 with near-zero quality loss
        and is the recommended default. q4_0 halves again but degrades
        generation speed at long context (~37% slower at 110K tokens).
      '';
    };

    ubatchSize = lib.mkOption {
      type = lib.types.int;
      default = 1024;
      description = ''
        Physical micro-batch size (-ub) for GPU kernel dispatch during prompt
        processing. Higher values improve prefill throughput on long prompts.
        1024 is the tuned optimum for AMD RDNA 3.5 / Strix Halo (gfx1151) on
        RADV — benchmarked by lhl/strix-halo-testing. For discrete RDNA 4
        (R9700) or NVIDIA, 2048 is reasonable; reduce to 512 if VRAM is
        extremely tight.
      '';
    };

    cacheRamMiB = lib.mkOption {
      type = lib.types.int;
      default = 8192;
      description = ''
        Disk-backed prompt cache size in MiB (--cache-ram). llama-server's own
        default is 8192. Set to 0 to disable, -1 for unlimited.

        Whether to enable this is **model-architecture-specific**:

        - **Standard transformers** (Llama, Mistral, Gemma, Qwen3-Coder dense,
          most others) support partial KV cache sequence removal, which is the
          mechanism that `--cache-reuse` relies on to skip re-prefill across
          requests with a shared prefix. For these the disk-backed cache is a
          big win for multi-turn chat — leave at the default 8192 or higher.

        - **Hybrid attention models** (Qwen3.6, Qwen3-Next, RWKV-style SSM
          variants) cannot do partial sequence removal because their recurrent
          layers carry rolled-up state. llama-server silently disables cache
          reuse for them and forces full prompt re-processing on every turn.
          The disk-backed cache is then **pure overhead** — measured in
          production, llama-server wrote 150-200 MiB of KV state per turn to
          the cache path and never read it back. The serialization itself was
          slow (5-30 seconds per turn, despite NVMe sequential bandwidth being
          1.8 GB/s — likely an O(n²) or lock-contended code path in llama.cpp
          for hybrid models). **Always set 0 for hybrid models.**

        See https://github.com/ggml-org/llama.cpp/pull/13194#issuecomment-2868343055
        for the upstream context on why hybrid attention disables cache reuse.
      '';
    };

    flashAttn = lib.mkOption {
      type = lib.types.enum [ "auto" "on" "off" ];
      default = "auto";
      description = ''
        Flash attention mode (--flash-attn). "auto" enables FA when the backend
        supports it natively. Set to "off" on hardware where FA triggers CUDA
        driver crashes (e.g. Blackwell sm_120 GSP firmware instability on
        RTX 50 series). Disabling FA costs ~4–10% throughput.
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional CLI flags appended to the base llama-server flags.
        The base flags (GPU offload, flash-attn, KV quant, context, priority,
        cache-reuse, parallel slots) are always applied. Use this for
        model-specific flags like --jinja.
      '';
    };

    cuda = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable CUDA GPU acceleration. Does not change the package — CUDA support
        is compiled in when nixpkgs.config.cudaSupport = true (set automatically
        by mine.nvidia-cuda). This flag exists to opt-in to the service hardening
        overrides required for CUDA: disabling MemoryDenyWriteExecute (CUDA PTX
        JIT requires W+X pages) and granting render/video group access.
      '';
    };

    rocm = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use the ROCm/HIP backend (pkgs.llama-cpp-rocm) instead of the default
        CPU-only build. Required for AMD GPU acceleration on RDNA and CDNA cards.
        Automatically disables MemoryDenyWriteExecute (ROCm JIT requires W+X pages).

        Mutually exclusive with `vulkan`. On RDNA 4 (gfx1201, R9700) the Vulkan
        backend is currently more stable and frequently faster than ROCm/HIP for
        llama.cpp inference; prefer `vulkan = true` unless you specifically need
        HIP-only features.
      '';
    };

    rocmVisibleDevices = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Value for ROCR_VISIBLE_DEVICES environment variable. When set, restricts
        ROCm to only the listed GPU indices (0-based). Use when multiple AMD GPUs
        are present and you need to select a specific one (e.g. "1" for the second
        GPU). Leave null to let ROCm use all available devices.
      '';
      example = "1";
    };

    vulkan = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use the Vulkan backend (pkgs.llama-cpp-vulkan) instead of the default
        CPU-only build. Works across AMD, Intel, and NVIDIA GPUs via the platform's
        Vulkan driver (RADV on AMD, ANV on Intel, NV proprietary on NVIDIA).

        Recommended for AMD RDNA 4 (gfx1201, e.g. R9700) where the community has
        converged on Vulkan over ROCm/HIP for stability and throughput in 2026.
        Confirmed working configurations on R9700 routinely report 30-100+ tok/s
        with K-quant models.

        Unlike ROCm, Vulkan does NOT require /dev/kfd — only /dev/dri/renderD*.
        Applies the same service hardening relaxations as ROCm (the DynamicUser
        sandbox still blocks GPU access without them) and sets MESA_SHADER_CACHE_DIR
        into systemd's CacheDirectory so the Mesa pipeline cache persists across
        service restarts (massive cold-start improvement after the first warmup).

        Mutually exclusive with `rocm`.
      '';
    };

    rocmfp4 = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Use the ROCmFP4 fork of llama.cpp (charlie12345/rocmfp4-llama) instead
        of any nixpkgs-provided package. Builds from source via this flake's
        `pkgs/rocmfp4-llama/package.nix` derivation; the resulting binary
        contains both HIP/ROCm and Vulkan backends in one image.

        Specifically targeted at AMD Strix Halo (gfx1151) — adds custom 4-bit
        quantization formats (Q4_0_ROCMFP4, Q4_0_ROCMFP4_FAST) and tensor-aware
        STRIX / STRIX_LEAN presets. Reported decode on Qwen3.6-35B-A3B-MTP at
        262K context: 80-104 tok/s short, 70-89 tok/s sustained (vs ~22-45
        tok/s on stock Vulkan llama.cpp on the same hardware).

        Runtime backend is selected by the `-dev` flag at server startup; the
        rocmfp4 option here just selects which compiled binary to use.

        Requires HSA_OVERRIDE_GFX_VERSION=11.5.1 and
        GGML_HIP_ENABLE_UNIFIED_MEMORY=1 (set automatically by this module
        when rocmfp4 = true).

        Mutually exclusive with `rocm`, `vulkan`, and `cuda` (the binary
        already includes both HIP and Vulkan).

        Note: experimental research build. Numbers are
        hardware/driver/model/prompt sensitive. Pinned to a specific upstream
        commit; bump `rev` + `hash` in pkgs/rocmfp4-llama/package.nix to
        track the branch.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
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
      #   - llama-cpp-rocm:   libggml-hip.so for RDNA/CDNA via ROCm/HIP.
      #   - llama-cpp-vulkan: libggml-vulkan.so for any Vulkan-capable GPU.
      #   - rocmfp4Package:   custom fork with ROCmFP4 quants + dual HIP/Vulkan.
      package = selectedPackage;

      settings = {
        inherit (cfg) host port;
        # GPU offload: push all transformer layers to VRAM.
        n-gpu-layers = 99;
        # Flash attention: confirmed real gains on RDNA 4 (GFX1201 / KHR_coopmat):
        # +4-11% prefill throughput, +4% generation throughput vs no-FA.
        # Configurable because Blackwell GSP firmware can crash under FA load.
        flash-attn = cfg.flashAttn;
        # KV cache quantization: symmetric type required for fused flash attention
        # kernel. q8_0 halves VRAM vs f16 with near-zero quality loss.
        cache-type-k = cfg.kvCacheQuant;
        cache-type-v = cfg.kvCacheQuant;
        # Context window — override via contextSize option.
        ctx-size = cfg.contextSize;
        # Physical micro-batch: larger values give faster prefill on long prompts.
        # Logical batch size (-b) is left at the server default (2048).
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
      openFirewall = true;
    };

    # GPU-specific service hardening overrides.
    # CUDA (PTX JIT) and ROCm (HIP JIT) require W+X memory pages at runtime.
    # The upstream nixpkgs unit sets MemoryDenyWriteExecute=true and PrivateUsers=true.
    # Vulkan does not JIT in the same way, but the DynamicUser sandbox still
    # blocks /dev/dri access without these relaxations, and PrivateUsers=true
    # breaks render/video group propagation. Apply the same overrides for all
    # GPU backends including the rocmfp4 fork (which is HIP-based + Vulkan).
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
          MemoryDenyWriteExecute = lib.mkForce false;
          PrivateUsers = lib.mkForce false;
          # GPU compute requires access to /dev/kfd (ROCm) or /dev/nvidia* (CUDA) and
          # /dev/dri/renderD* (all backends, including Vulkan). The DynamicUser sandbox
          # needs these group memberships.
          SupplementaryGroups = [ "render" "video" ];
        };

        environment = lib.mkMerge [
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
  };
}
