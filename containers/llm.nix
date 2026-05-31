{ ... }:

{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  nixpkgs.config.allowUnfree = true;

  hardware.graphics.enable = true;

  networking.hostName = "llm";

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
      cuda = true;
      host = "0.0.0.0";
      port = 8080;
      modelsDir = "/var/lib/llama-cpp/models";

      # Gemma 4 26B-A4B MoE: 25B total / 3.8B active params, SWA hybrid attention.
      # Chosen for Open WebUI chat use case where multi-turn TTFT dominates feel:
      # SWA + --swa-full enables full KV cache reuse in llama.cpp ≥ b8819 (PR #22288),
      # so follow-up turns hit cached prefix and emit first token in <1s regardless
      # of conversation length. Qwen3.6's hybrid GDN architecture forces full
      # re-prefill every turn (~11s at 8K history on this hardware) — disqualifying
      # for interactive chat despite slightly stronger coding scores.
      #
      # UD-Q3_K_XL is the quality/fit sweet spot for 16 GB VRAM:
      #   weights 12.9 GB + KV ~0.7 GB (32K q4_0) + compute ~1.2 GB ≈ 14.8 GB total.
      # This allows hitting the 32K context target while preserving high quality
      # through Unsloth's Dynamic 2.0 quantization.
      #
      # Quality (Google-published, instruction-tuned):
      #   MMLU Pro 82.6%, GPQA Diamond 82.3%, AIME 2026 88.3%, MMMLU 86.3%.
      # Top-tier general reasoning for a 4B-active model.
      hfRepo = "unsloth/gemma-4-26B-A4B-it-GGUF";
      hfFile = "gemma-4-26B-A4B-it-UD-Q3_K_XL.gguf";

      contextSize = 32768; # 32K. Achieved via q4_0 KV quantization.
      kvCacheQuant = "q4_0"; # Required to fit 32K context + weights in 16 GB VRAM.
      flashAttn = "off"; # Blackwell sm_120 has multiple recent FA-related bugs:
      # - #23717: q8_0/q8_0 + FA gibberish on RTX 5060 Ti
      # - #23693: q4_0 KV + FA garbled output regression vs b9174
      # - #23210: CUDA crash on Qwen3.6-27B + FA + MTP at long ctx
      # All filed against this exact GPU. Disabling FA uses stable vanilla
      # CUDA kernels which support quantized KV without these regressions.
      ubatchSize = 2048; # CUDA Blackwell tuning. Module default 1024 is for AMD
      # RDNA 3.5 APU (Strix Halo); the option doc already notes
      # 2048 is reasonable for discrete NVIDIA.
      cacheRamMiB = 8192; # Default. Gemma 4 SWA + --swa-full supports partial KV
      # sequence removal, so the disk-backed prompt cache is a
      # real multi-turn win (13× warm-prefill speedup confirmed
      # in PR #22288 review).

      extraFlags = [
        "--jinja"
        "--no-mmproj"
        "--swa-full" # CRITICAL: enables KV cache reuse on Gemma 4 SWA hybrid.
        # Without this, llama-server treats SWA layers as non-reusable
        # and re-prefills the full conversation history every turn,
        # negating the entire reason we picked this model over Qwen3.6.
        # Thinking mode is off by default (no <|think|> token in template).
        # Per-conversation thinking enabled via Open WebUI Workspace preset
        # with chat_template_kwargs={"enable_thinking": true}; see docs/OPENWEBUI.md
        # for the existing Qwen3.6 pattern that translates directly to Gemma 4.
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
