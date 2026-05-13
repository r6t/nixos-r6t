{ lib, config, pkgs, ... }:
let
  cfg = config.mine.llama-cpp;
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
      default = 2048;
      description = ''
        Physical micro-batch size (-ub) for GPU kernel dispatch during prompt
        processing. Higher values improve prefill throughput on long prompts.
        2048 is a good default; reduce to 512 if VRAM is extremely tight.
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
        Automatically disables MemoryDenyWriteExecute (ROCm JIT requires W+X pages)
        and sets RADV_PERFTEST=nogttspill for better Vulkan/display performance.

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
        Sets RADV_PERFTEST=nogttspill (recommended for all RADV users by llama.cpp
        Vulkan maintainers) and applies the same service hardening relaxations as
        ROCm (the DynamicUser sandbox still blocks GPU access without them).

        Mutually exclusive with `rocm`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(cfg.rocm && cfg.vulkan);
        message = "mine.llama-cpp: `rocm` and `vulkan` are mutually exclusive — pick one GPU backend.";
      }
    ];

    services.llama-cpp = {
      enable = true;
      inherit (cfg) host port modelsPreset;

      # GPU backend selection. The default nixpkgs llama-cpp is CPU-only.
      #   - llama-cpp-rocm:    libggml-hip.so for RDNA/CDNA via ROCm/HIP.
      #   - llama-cpp-vulkan:  libggml-vulkan.so for any Vulkan-capable GPU.
      package =
        if cfg.rocm then pkgs.llama-cpp-rocm
        else if cfg.vulkan then pkgs.llama-cpp-vulkan
        else pkgs.llama-cpp;

      extraFlags = [
        # GPU offload: push all transformer layers to VRAM.
        "-ngl"
        "99"
        # Flash attention: confirmed real gains on RDNA 4 (GFX1201 / KHR_coopmat):
        # +4-11% prefill throughput, +4% generation throughput vs no-FA.
        # Configurable because Blackwell GSP firmware can crash under FA load.
        "--flash-attn"
        cfg.flashAttn
        # KV cache quantization: symmetric type required for fused flash attention
        # kernel. q8_0 halves VRAM vs f16 with near-zero quality loss.
        "--cache-type-k"
        cfg.kvCacheQuant
        "--cache-type-v"
        cfg.kvCacheQuant
        # Context window — override via contextSize option.
        "-c"
        (toString cfg.contextSize)
        # Physical micro-batch: larger values give faster prefill on long prompts.
        # Logical batch size (-b) is left at the server default (2048).
        "-ub"
        (toString cfg.ubatchSize)
        # High process priority — GPU is dedicated to LLM inference.
        "--prio"
        "2"
        # KV prefix reuse across requests (system prompt caching).
        "--cache-reuse"
        "256"
        # Single parallel slot — all VRAM to one session.
        "-np"
        "1"
      ]
      ++ cfg.extraFlags
      ++ lib.optionals (cfg.modelFile != null) [ "--model" cfg.modelFile ]
      ++ lib.optionals (cfg.modelsDir != null) [ "--models-dir" cfg.modelsDir ]
      ++ lib.optionals (cfg.hfRepo != null) [ "--hf-repo" cfg.hfRepo ]
      ++ lib.optionals (cfg.hfFile != null) [ "--hf-file" cfg.hfFile ];
      openFirewall = true;
    };

    # GPU-specific service hardening overrides.
    # CUDA (PTX JIT) and ROCm (HIP JIT) require W+X memory pages at runtime.
    # The upstream nixpkgs unit sets MemoryDenyWriteExecute=true and PrivateUsers=true.
    # Vulkan does not JIT in the same way, but the DynamicUser sandbox still
    # blocks /dev/dri access without these relaxations, and PrivateUsers=true
    # breaks render/video group propagation. Apply the same overrides for all
    # three GPU backends.
    systemd.services.llama-cpp = lib.mkIf (cfg.rocm || cfg.cuda || cfg.vulkan) {
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
        (lib.optionalAttrs (cfg.rocm || cfg.vulkan) {
          # RADV_PERFTEST=nogttspill: recommended for all RADV (AMD Vulkan) users by the
          # llama.cpp Vulkan benchmark maintainer. Fixes performance issues on AMD cards
          # including RDNA 4 (GFX1201). Applied for both Vulkan (the actual backend) and
          # ROCm (since the display compositor still uses RADV when present).
          RADV_PERFTEST = "nogttspill";
        })
        (lib.optionalAttrs (cfg.rocm && cfg.rocmVisibleDevices != null) {
          # Restrict ROCm to a specific GPU by index. Use when multiple AMD GPUs are
          # present (e.g. mountainball: 780M iGPU + R9700 eGPU) to ensure llama-server
          # uses the discrete eGPU rather than the integrated graphics.
          ROCR_VISIBLE_DEVICES = cfg.rocmVisibleDevices;
        })
      ];
    };
  };
}
