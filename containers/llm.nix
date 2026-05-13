let
  # ---------------------------------------------------------------------------
  # Model catalogue (32 GiB Radeon AI Pro R9700, RDNA 4 / GFX1201).
  # All models accumulate on persistent storage at:
  #   crown host:    /mnt/crownstore/app-storage/llama-cpp/models/
  #   container:     /var/lib/llama-cpp/models/
  # Pre-download: drop the GGUF into the host path above.
  # On first start, llama-server auto-downloads from HF if not present.
  #
  # Role: general-purpose chat, document Q&A, creative writing, vision.
  # Coding is handled by mountainball (also R9700 32 GB, separate model).
  #
  # VRAM budget at Q8_0 on 32 GiB:
  #   weights + KV cache + framework overhead + (optional) mmproj vision encoder
  #   contextSize is set per-model based on remaining VRAM after weights.
  #   kvCacheQuant = "q8_0" halves KV VRAM vs f16 with near-zero quality loss.
  #
  # To switch models, change `activeModel` to one of the keys below.
  # ---------------------------------------------------------------------------
  models = {
    # PRIMARY: Best general-purpose model that fits 32 GiB at Q8_0.
    # Dense 27B. Weights ~27 GiB at Q8_0. Most Claude-like local option per
    # harness-bench (15/16 with opencode at Q8). Same model mountainball uses.
    # Supports /think per-prompt extended thinking (Qwen3 native feature).
    # --jinja: required for correct Qwen3 tool-use prompt formatting.
    qwen3-6-27b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3.6-27B-Q8_0.gguf";
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q8_0.gguf";
      contextSize = 131072; # 128K — 32 GiB easily holds this at q8_0 KV.
      extraFlags = [ "--jinja" ];
    };

    # ALTERNATIVE: Best vision/document quality. Use when OCR, chart reading,
    # or document extraction is the primary task.
    # Dense 7B. Weights ~8.1 GiB at Q8_0, leaving ample VRAM for KV cache.
    # DocVQA 95.7 (best in class), ChartQA 87.3, TextVQA 84.9. Weaker on
    # general reasoning vs 27B.
    qwen2-5-vl-7b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen2.5-VL-7B-Instruct-Q8_0.gguf";
      hfRepo = "unsloth/Qwen2.5-VL-7B-Instruct-GGUF";
      hfFile = "Qwen2.5-VL-7B-Instruct-Q8_0.gguf";
      contextSize = 65536;
      extraFlags = [ "--jinja" ];
    };
  };

  # Change this one line to switch models:
  # qwen3-6-27b (primary) | qwen2-5-vl-7b (best vision)
  activeModel = models.qwen3-6-27b;

in
{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
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
    llama-cpp = {
      enable = true;
      host = "0.0.0.0";
      modelsDir = "/var/lib/llama-cpp/models";
      inherit (activeModel) modelFile hfRepo hfFile contextSize extraFlags;
      # q8_0 KV quantization: halves KV cache VRAM vs f16, near-zero quality
      # loss, and preserves the fused flash attention kernel (symmetric K/V).
      kvCacheQuant = "q8_0";
      # Default ubatch (2048) — 32 GiB R9700 has plenty of room for the
      # compute graph at this size, and prefill throughput benefits significantly.
      ubatchSize = 2048;
      # Flash attention: confirmed real gains on RDNA 4 (GFX1201 / KHR_coopmat).
      # +4-11% prefill, +4% generation throughput vs no-FA.
      flashAttn = "auto";
      # ROCm/HIP backend for AMD GPU acceleration. Selects pkgs.llama-cpp-rocm
      # (default nixpkgs llama-cpp is CPU-only) and applies service hardening
      # overrides: disables MemoryDenyWriteExecute (HIP JIT requires W+X pages),
      # disables PrivateUsers, grants render/video group access, sets
      # RADV_PERFTEST=nogttspill.
      rocm = true;
      # Crown is single-GPU (R9700 only) — no rocmVisibleDevices restriction needed.
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
