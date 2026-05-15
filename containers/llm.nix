{ lib, ... }:

let
  models = {
    # 1. Quality fallback / one-shot Q&A
    qwen3-6-27b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3.6-27B-Q6_K.gguf";
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q6_K.gguf";
      contextSize = 65536;
      cacheRamMiB = 0;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    # 2. MoE Standard, coding-optimized, non-thinking, fast multi-turn
    qwen3-coder-30b-a3b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF";
      hfFile = "Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf";
      contextSize = 65536;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" ];
    };

    # 3. MoE SWA Primary, snappy multi-turn (needs --swa-full)
    gemma4-26b-a4b = {
      modelFile = "/var/lib/llama-cpp/models/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/gemma-4-26B-A4B-it-GGUF";
      hfFile = "gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
      contextSize = 49152;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--swa-full" "--reasoning" "off" ];
    };

    # 4. Dense SWA fallback (deterministic alternative to MoE Gemma)
    gemma4-31b = {
      modelFile = "/var/lib/llama-cpp/models/gemma-4-31B-it-Q5_K_M.gguf";
      hfRepo = "unsloth/gemma-4-31B-it-GGUF";
      hfFile = "gemma-4-31B-it-Q5_K_M.gguf";
      contextSize = 65536;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--swa-full" "--reasoning" "off" ];
    };

    # 5. Dense Standard (The Balanced Best Choice)
    devstral-small-2-24b = {
      modelFile = "/var/lib/llama-cpp/models/Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF";
      hfFile = "Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      contextSize = 98304;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" ];
    };
  };

  # Set active to the best balanced model
  activeModel = models.devstral-small-2-24b;
in
{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];
  nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [ "open-webui" ];
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
      openaiApiUrls = [ "http://localhost:8080/v1" "https://openrouter.ai/api/v1" ];
      environmentFile = "/etc/oi.env";
    };
  };
}
