{ lib, ... }:

let
  # All model definitions and activeModel live in llm-config.nix so that
  # hosts/mountainball/configuration.nix can import activeModel.contextSize
  # and keep the opencode provider limit in sync without duplication.
  llmCfg = import ./lib/llm-config.nix;
  inherit (llmCfg) activeModel;
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
      # q4_0 halves KV VRAM vs q8_0 — enables full 256K context on 32 GB for
      # hybrid GDN models where KV is tiny (only 5/64 layers use traditional KV).
      kvCacheQuant = "q4_0";
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
