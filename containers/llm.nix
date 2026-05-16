{ lib, ... }:

let
  # Preload the best coding model
  preloadedModel = {
    modelFile = "/var/lib/llama-cpp/models/Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf";
    hfRepo = "unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF";
    hfFile = "Qwen3-Coder-30B-A3B-Instruct-UD-Q6_K_XL.gguf";
    contextSize = 65536;
    cacheRamMiB = 8192;
    extraFlags = [ "--jinja" "--no-mmproj" ];
  };
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
