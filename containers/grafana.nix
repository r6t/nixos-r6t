{ config, pkgs, lib, userConfig, ... }:
{
  imports = [
    ./r6-tailnet-base.nix
    ../modules/nixos/grafana/default.nix
  ];
  mine.grafana.enable = true;
  # Systemd dependencies
  systemd.services.jellyfin.after = [ "tailscale.service" ];
}

