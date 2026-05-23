{ lib, ... }:

{
  imports = [
    ../modules/nixos/llama-cpp/default.nix
    ../modules/nixos/open-webui/default.nix
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  nixpkgs.config.allowUnfreePredicate = pkg:
    builtins.elem (lib.getName pkg) [ "open-webui" ];

  hardware.graphics.enable = false;

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
      enable = false;
    };
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      openaiApiUrls = [
        "https://llm.r6t.io/v1"
        "https://openrouter.ai/api/v1"
      ];
      environmentFile = "/etc/oi.env";
    };
  };
}
