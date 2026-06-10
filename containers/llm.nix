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

      # Qwen3 14B @ Q4_K_M: 9 GB model, standard transformer architecture.
      # Standard transformer → KV cache reuse between turns works, giving fast
      # multi-turn chat. 9 GB model on 16 GB GPU leaves ~7 GB headroom for
      # context, enabling 64K context comfortably.
      #
      # Switching models is a Nix rebuild away: change hfRepo/hfFile/contextSize
      # below, then `nrs` on crown to rebuild the container and relaunch it.
      #
      # Quality: ~71.5% MMLU Pro, 14B class. Not the top tier but solid.
      # For coding work, goldenball handles the heavy models (ROCmFP4 35B-MTP).
      hfRepo = "unsloth/Qwen3-14B-GGUF";
      hfFile = "Qwen3-14B-Q4_K_M.gguf";

      contextSize = 65536; # 64K. 14B @ Q4_K_M uses ~9 GB, leaving ~7 GB headroom.
      kvCacheQuant = "q4_0"; # Halves KV cache VRAM vs f16.
      flashAttn = "off"; # Blackwell sm_120 has multiple FA-related bugs:
      # - #23717: q8_0/q8_0 + FA gibberish on RTX 5060 Ti
      # - #23693: q4_0 KV + FA garbled output regression vs b9174
      # - #23210: CUDA crash on Qwen3.6-27B + FA + MTP at long ctx
      # All filed against this exact GPU. Disabling FA uses stable vanilla
      # CUDA kernels which support quantized KV without these regressions.
      ubatchSize = 2048; # CUDA Blackwell tuning. Module default 1024 is for AMD
      # RDNA 3.5 APU (Strix Halo); the option doc already notes
      # 2048 is reasonable for discrete NVIDIA.
      cacheRamMiB = 8192; # Standard transformer supports --cache-reuse.
      # Disk-backed prompt cache gives warm-prefill speedup across turns.

      extraFlags = [
        "--jinja"
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
