{ config, pkgs, lib, userConfig, ... }:
{
  imports = [
    ./r6-tailnet-base.nix
    ../modules/nixos/jellyfin/default.nix
  ];
  mine.jellyfin.enable = true;
  # Systemd dependencies
  systemd.services.jellyfin.after = [ "tailscale.service" ];
}

