{ lib, ... }:

let
  models = {
    qwen3-6-27b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3.6-27B-Q6_K.gguf";
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q6_K.gguf";
      contextSize = 65536;
      cacheRamMiB = 0;
      extraFlags = [ "--jinja" "--no-mmproj" "--reasoning" "off" ];
    };

    qwen3-coder-30b-a3b = {
      modelFile = "/var/lib/llama-cpp/models/Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF";
      hfFile = "Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf";
      contextSize = 65536;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" ];
    };

    gemma4-26b-a4b = {
      modelFile = "/var/lib/llama-cpp/models/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/gemma-4-26B-A4B-it-GGUF";
      hfFile = "gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
      contextSize = 49152;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--swa-full" "--reasoning" "off" ];
    };

    gemma4-31b = {
      modelFile = "/var/lib/llama-cpp/models/gemma-4-31B-it-Q5_K_M.gguf";
      hfRepo = "unsloth/gemma-4-31B-it-GGUF";
      hfFile = "gemma-4-31B-it-Q5_K_M.gguf";
      contextSize = 65536;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--swa-full" "--reasoning" "off" ];
    };

    devstral-small-2-24b = {
      modelFile = "/var/lib/llama-cpp/models/Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/Devstral-Small-2-24B-Instruct-2512-GGUF";
      hfFile = "Devstral-Small-2-24B-Instruct-2512-UD-Q6_K_XL.gguf";
      contextSize = 98304;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" ];
    };
  };

  # Preload the best coding model
  preloadedModel = models.qwen3-coder-30b-a3b;

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
      # Eagerly load the coder
      inherit (preloadedModel) modelFile hfRepo hfFile contextSize cacheRamMiB extraFlags;
      # Expose ALL as presets for Router Mode
      modelsPreset = models;
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
