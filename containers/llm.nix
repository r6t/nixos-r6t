let
  gpu = import ../hosts/crown/gpu.nix;

  # ---------------------------------------------------------------------------
  # Model catalogue (16 GiB RTX 5060 Ti, verified May 2026).
  # All models accumulate on persistent storage at:
  #   crown host:    /mnt/crownstore/app-storage/llama-cpp/models/
  #   container:     /var/lib/llama-cpp/models/
  # Pre-download: drop the GGUF into the host path above.
  # On first start, llama-server auto-downloads from HF if not present.
  #
  # Role: general-purpose chat, document Q&A, creative writing, vision.
  # Coding is handled by mountainball (R9700 32GB, separate model).
  #
  # VRAM budget at Q4_K_M on 16 GiB:
  #   weights + mmproj vision encoder + KV cache + framework overhead
  #   Minimum acceptable quant: Q4_K_M (no IQ3/Q3/IQ2).
  #   contextSize is set per-model based on remaining VRAM after weights.
  #   kvCacheQuant = "q8_0" halves KV VRAM vs f16 with near-zero quality loss.
  #
  # To switch models, change `activeModel` to one of the keys below.
  # ---------------------------------------------------------------------------
  models = {
    # PRIMARY: Best quality that fits 16 GiB at Q4_K_M.
    # Dense 24B. Weights: 13.3 GiB GPU + 0.36 GiB CPU. Compute graph: ~1.17 GiB.
    # Remaining for KV: ~1.24 GiB → 16K context at q8_0 (1.34 GiB) is the safe ceiling.
    # Vision via mmproj (llama.cpp libmtmd). Strong multimodal: DocVQA 94.1,
    # MMMU 64.0, ChartQA 86.2, MM-MT-Bench 7.3. Best text quality (MMLU 80.6)
    # of any model that fits 16 GiB at Q4. Apache 2.0.
    mistral-small-3-1-24b = {
      modelFile = "/var/lib/llama-cpp/models/Mistral-Small-3.1-24B-Instruct-2503-Q4_K_M.gguf";
      hfRepo = "unsloth/Mistral-Small-3.1-24B-Instruct-2503-GGUF";
      hfFile = "Mistral-Small-3.1-24B-Instruct-2503-Q4_K_M.gguf";
      contextSize = 16384; # 16K — measured safe max: 15712 MiB free, 13302 weights, 1168 compute = ~1242 MiB for KV.
      extraFlags = [ "--jinja" ];
    };

    # ALTERNATIVE: Best vision/document quality. Use when OCR, chart reading,
    # or document extraction is the primary task.
    # Dense 7B. Weights: ~8.1 GiB at Q8_0, leaving ~7.9 GiB for KV cache.
    # With q8_0 KV quant: 48K+ usable context. DocVQA 95.7 (best in class),
    # ChartQA 87.3, TextVQA 84.9. Weaker on general reasoning vs 24B models.
    qwen2-5-vl-7b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen2.5-VL-7B-Instruct-Q8_0.gguf";
      hfRepo = "unsloth/Qwen2.5-VL-7B-Instruct-GGUF";
      hfFile = "Qwen2.5-VL-7B-Instruct-Q8_0.gguf";
      contextSize = 32768; # Conservative default; can push to 65536 at q8_0 KV.
      extraFlags = [ "--jinja" ];
    };
  };

  # Change this one line to switch models:
  # mistral-small-3-1-24b (primary) | qwen2-5-vl-7b (best vision)
  activeModel = models.mistral-small-3-1-24b;

in
{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
    ../modules/nixos/nvidia-cuda/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  networking.hostName = "llm";

  # Precreate private state dirs (root-owned. systemd will manage perms for DynamicUser)
  # These appear in the rootfs so Incus can bind-mount to them before systemd starts.
  systemd.tmpfiles.rules = [
    "d /var/lib/private 0700 root root -"
    "d /var/lib/private/open-webui 0700 root root -"
    "d /var/lib/private/llama-cpp 0700 root root -"
    "d /var/cache/private 0700 root root -"
    "d /var/cache/private/llama-cpp 0700 root root -"
  ];

  mine = {
    nvidia-cuda = {
      enable = true;
      package = gpu.driverPackage;
      installCudaToolkit = false;
    };
    llama-cpp = {
      enable = true;
      host = "0.0.0.0";
      modelsDir = "/var/lib/llama-cpp/models";
      inherit (activeModel) modelFile hfRepo hfFile contextSize extraFlags;
      # q8_0 KV quantization: halves KV cache VRAM vs f16, near-zero quality
      # loss, and preserves the fused flash attention kernel (symmetric K/V).
      # Essential for 24B models on 16 GiB to achieve usable context windows.
      kvCacheQuant = "q8_0";
      # CUDA GPU acceleration. The llama-cpp package gets CUDA support
      # automatically when nixpkgs.config.cudaSupport = true (set by
      # mine.nvidia-cuda above). This flag enables the required service
      # hardening overrides: disabling MemoryDenyWriteExecute (CUDA PTX JIT
      # requires W+X pages), PrivateUsers, and granting render/video group access.
      cuda = true;
    };
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      openaiApiUrls = [
        # Local llama-server (no key required)
        "http://localhost:8080/v1"
        # OpenRouter — full model catalogue available in the UI picker.
        "https://openrouter.ai/api/v1"
      ];
      # Secrets and OAuth config injected at runtime via environmentFile.
      # Bind-mounted from host at /mnt/crownstore/Sync/app-config/open-webui/oi.env
      # Contains: OPENAI_API_KEYS, OAuth/OIDC config (Pocket ID), etc.
      environmentFile = "/etc/oi.env";
    };
  };
}
