{ lib, ... }:

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

    gpuLayers = lib.mkOption {
      type = lib.types.oneOf [ lib.types.int lib.types.str ];
      default = 99;
      description = ''
        Max transformer layers to store in VRAM, passed as --n-gpu-layers.
        Use "auto" to let llama.cpp fit GPU offload to available device memory.
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

    batchSize = lib.mkOption {
      type = lib.types.int;
      default = 2048;
      description = ''
        Logical maximum batch size (-b) used during prompt processing. Lower
        this on memory-constrained GPUs to reduce CUDA compute buffer pressure.
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
        cache-ram, parallel slots) are always applied. Use this for
        model-specific flags like --jinja.
      '';
    };

    cuda = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Enable CUDA GPU acceleration using a CUDA-enabled pkgs.llama-cpp. This
        is the NVIDIA path used by crown's llm container. The flag also opts in
        to the service hardening overrides required for CUDA: disabling
        MemoryDenyWriteExecute (CUDA PTX JIT requires W+X pages) and granting
        render/video group access.
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
}
