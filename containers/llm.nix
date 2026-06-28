{ config, pkgs, ... }:

{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  nixpkgs.config = {
    allowUnfree = true;
    cudaSupport = true;
    nvidia.acceptLicense = true;
  };

  hardware.graphics.enable = true;

  environment.systemPackages = [ config.services.llama-cpp.package ];

  networking.hostName = "llm";

  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
    "d /var/lib/private/open-webui 0700 root root -"
    "d /var/lib/private/llama-cpp 0700 root root -"
    "d /var/cache/private 0700 root root -"
    "d /var/cache/private/llama-cpp 0700 root root -"
  ];

  # Crown's Incus NVIDIA runtime mounts versioned driver libraries into
  # /usr/lib64. llama.cpp's CUDA backend dlopens the libcuda.so.1 SONAME.
  systemd.services = {
    llama-cpp = {
      after = [ "llama-cpp-cuda-driver-libs.service" ];
      wants = [ "llama-cpp-cuda-driver-libs.service" ];
      environment = {
        LD_LIBRARY_PATH = "/usr/lib64";
        # CUDA graphs crashed the 595.84 GSP driver on RTX 5060 Ti during
        # llama.cpp validation; keep Blackwell on the non-graphs CUDA path.
        GGML_CUDA_DISABLE_GRAPHS = "1";
        # Prefer lower-VRAM custom quantized matmul kernels over cuBLAS. This is
        # slower for prefill on some GPUs but leaves more headroom on 16 GB.
        GGML_CUDA_FORCE_MMQ = "1";
        CUDA_MODULE_LOADING = "LAZY";
      };
      serviceConfig.ExecStartPre = [
        "+${pkgs.writeShellScript "llama-cpp-cuda-preflight" ''
          set -eu
          export LD_LIBRARY_PATH=/usr/lib64

          devices="$(${config.services.llama-cpp.package}/bin/llama-bench --list-devices 2>&1)"
          printf '%s\n' "$devices"
          printf '%s\n' "$devices" | grep -q 'CUDA0:'
        ''}"
      ];
    };

    llama-cpp-cuda-driver-libs = {
      description = "Create NVIDIA driver library SONAME symlinks for llama.cpp CUDA";
      before = [ "llama-cpp.service" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        set -eu

        link_latest() {
          soname="$1"
          latest=""

          for candidate in /usr/lib64/"$soname".*; do
            if [ -e "$candidate" ] && [ "$candidate" != "/usr/lib64/$soname.1" ]; then
              latest="$candidate"
            fi
          done

          if [ -n "$latest" ]; then
            ln -sfn "$(basename "$latest")" "/usr/lib64/$soname.1"
          fi
        }

        link_latest libcuda.so
        link_latest libnvidia-ml.so
      '';
    };
  };

  mine = {
    llama-cpp = {
      enable = true;
      cuda = true;
      host = "0.0.0.0";
      port = 8080;
      modelsDir = "/var/lib/llama-cpp/models";

      # Qwen3 14B @ Q4_K_M: 9 GB model, standard transformer architecture.
      # Standard transformer → KV cache reuse between turns works, giving fast
      # multi-turn chat. This container is dedicated to crown's RTX 5060 Ti and
      # must fail closed rather than falling back to CPU inference.
      #
      # Switching models is a Nix rebuild away: change hfRepo/hfFile/contextSize
      # below, then `nrs` on crown to rebuild the container and relaunch it.
      #
      # Quality: ~71.5% MMLU Pro, 14B class. Not the top tier but solid.
      # For coding work, goldenball handles the heavy models (ROCmFP4 35B-MTP).
      hfRepo = "unsloth/Qwen3-14B-GGUF";
      hfFile = "Qwen3-14B-Q4_K_M.gguf";

      gpuLayers = "all"; # Require full model offload to the RTX 5060 Ti.
      contextSize = 32768; # Native Qwen3-14B context; fits with conservative CUDA batch sizes.
      kvCacheQuant = "f16"; # Current llama.cpp requires flash-attn for quantized V cache.
      flashAttn = "off"; # Blackwell sm_120 has multiple FA-related bugs:
      # - #23717: q8_0/q8_0 + FA gibberish on RTX 5060 Ti
      # - #23693: q4_0 KV + FA garbled output regression vs b9174
      # - #23210: CUDA crash on Qwen3.6-27B + FA + MTP at long ctx
      # All filed against this exact GPU. Disabling FA uses the stable vanilla
      # CUDA path; keep KV f16 while FA is disabled.
      batchSize = 512; # Reduce CUDA compute-buffer pressure during prompt prefill.
      ubatchSize = 128; # Keep CUDA launch/memory pressure low on 595.84 + Blackwell.
      cacheRamMiB = 8192; # Standard transformer supports --cache-reuse.
      # Disk-backed prompt cache gives warm-prefill speedup across turns.

      extraFlags = [
        "--device"
        "CUDA0"
        "--jinja"
        "--reasoning"
        "off"
        "--no-mmproj"
        # Thinking mode off by default. Enable per-conversation via Open WebUI
        # Workspace preset with chat_template_kwargs={"enable_thinking": true}.
      ];
    };
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      openaiApiUrls = [
        "http://localhost:8080/v1"
        "https://openrouter.ai/api/v1"
      ];
      environmentFile = "/etc/oi.env";
    };
  };
}
