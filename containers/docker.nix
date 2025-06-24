{ config, pkgs, lib, userConfig, ... }:
{
  imports = [
    ./r6-tailnet-base.nix
    ../modules/nixos/docker/default.nix
  ];

  networking.hostName = "docker-lxc";

  mine.docker = {
    enable = true;
  };
  # Systemd dependencies
  systemd.services.jellyfin.after = [ "tailscale.service" ];
}

