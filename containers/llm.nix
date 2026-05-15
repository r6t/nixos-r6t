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
    gemma4-26b-a4b = {
      modelFile = "/var/lib/llama-cpp/models/gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
      hfRepo = "unsloth/gemma-4-26B-A4B-it-GGUF";
      hfFile = "gemma-4-26B-A4B-it-UD-Q6_K_XL.gguf";
      contextSize = 65536;
      cacheRamMiB = 8192;
      extraFlags = [ "--jinja" "--no-mmproj" "--swa-full" "--reasoning" "off" ];
    };
  };
  activeModel = models.gemma4-26b-a4b;
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
