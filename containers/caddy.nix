{ config, pkgs, lib, userConfig, ... }:
{
  imports = [
    ./r6-tailnet-base.nix
    ../modules/nixos/caddy/default.nix
  ];
  mine.caddy.enable = true;
  # Systemd dependencies
  systemd.services.jellyfin.after = [ "tailscale.service" ];
}

