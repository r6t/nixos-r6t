{ lib, ... }:

let
  models = {
    # ---------------------------------------------------------------------------
    # ACTIVE: Qwen3.6-35B-A3B — hybrid GatedDeltaNet MoE, UD-Q4_K_M (~20 GB).
    # Larger and smarter than the 27B sibling at a lower quant, still fits 32 GB.
    # NOTE: hybrid attention — cacheRamMiB = 0 is REQUIRED (same as qwen3-6-27b).
    # Multi-turn TTFT is multi-second (full re-prefill every turn); best for
    # one-shot Q&A and high-quality single-turn coding prompts.
    # Thinking off by default; opt-in per-request via enable_thinking kwarg.
    # ---------------------------------------------------------------------------
    qwen3-6-35b-a3b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
      hfRepo = "unsloth/Qwen3.6-35B-A3B-GGUF";
      hfFile = "Qwen3.6-35B-A3B-UD-Q4_K_M.gguf";
      contextSize = 65536;
      cacheRamMiB = 0;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    # ---------------------------------------------------------------------------
    # Qwen3.6-27B — hybrid GatedDeltaNet, Q6_K (~22.5 GB). Higher quant than
    # the 35B but fewer total params. Better quality-per-byte than 35B UD-Q4_K_M
    # on some benchmarks; useful if the 35B shows quality regressions from Q4.
    # Same hybrid attention caveats: cacheRamMiB = 0, multi-second TTFT.
    # ---------------------------------------------------------------------------
    qwen3-6-27b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3.6-27B-Q6_K.gguf";
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q6_K.gguf";
      contextSize = 65536;
      cacheRamMiB = 0;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    # ---------------------------------------------------------------------------
    # Qwen3-30B-A3B — standard MoE transformer (NOT hybrid GatedDeltaNet).
    # Snappy multi-turn, full KV cache reuse, coding + general purpose.
    # UD-Q6_K_XL (~26 GB) is tight on 32 GB but fits at 64K ctx.
    # ---------------------------------------------------------------------------
    qwen3-30b-a3b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3-30B-A3B-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Qwen3-30B-A3B-GGUF";
      hfFile = "Qwen3-30B-A3B-UD-Q6_K_XL.gguf";
      contextSize = 65536;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    # ---------------------------------------------------------------------------
    # Devstral-Small-2-24B — dense standard transformer, coding-optimised.
    # Most deterministic option, snappy multi-turn, comfortable VRAM headroom.
    # Good opencode backend when MoE routing variance is getting in the way.
    # ---------------------------------------------------------------------------
    devstral-small-2-24b = {
      modelFile = "/var/lib/llama-cpp/models/Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF";
      hfFile = "Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      contextSize = 98304;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" ];
    };

    # ---------------------------------------------------------------------------
    # gemma4-26b-a4b — MoE SWA (3.8B active / 26B total), ~21.7 GB weights.
    # Best decode speed on R9700 (~110-160 tok/s predicted). Snappy multi-turn
    # when llama.cpp >= b8819 + --swa-full (currently running b8983 ✓).
    # Leaves ~10 GB headroom — most comfortable VRAM budget of the lot.
    # Recommended if you want the fastest chat experience.
    # ---------------------------------------------------------------------------
    # gemma4-26b-a4b = {
    #   modelFile = "/var/lib/llama-cpp/models/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
    #   hfRepo = "unsloth/gemma-4-26B-A4B-it-GGUF";
    #   hfFile = "gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
    #   contextSize = 65536;
    #   cacheRamMiB = 8192;
    #   extraFlags = [ "--jinja" "--no-mmproj" "--swa-full" "--reasoning" "off" ];
    # };
  };

  # Change this one line to switch models:
  activeModel = models.qwen3-6-35b-a3b;

in
{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "open-webui" ];

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
      host = "0.0.0.0";
      modelsDir = "/var/lib/llama-cpp/models";
      inherit (activeModel) modelFile hfRepo hfFile contextSize cacheRamMiB extraFlags;
      kvCacheQuant = "q8_0";
      ubatchSize = 2048;
      flashAttn = "auto";
      vulkan = true;
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
