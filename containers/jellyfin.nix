{ config, pkgs, lib, userConfig, ... }:
{
  imports = [
    ./r6-tailnet-base.nix
    ../modules/nixos/jellyfin/default.nix
  ];

  networking.hostName = "jellyfin";

  mine.jellyfin = {
    enable = true;
    logDir = "/mnt/barrelstore/incus/logs/jellyfin";
    dataDir = "/mnt/thunderbay/8TB-D/storage/plex";
    # additional dataDir passed through via incus
    cacheDir = "/mnt/thunderbay/2TB-E/cache/jellyfin";
    configDir = "/mnt/thunderbay/2TB-E/config/jellyfin";
  };
  # Systemd dependencies
  systemd.services.jellyfin.after = [ "tailscale.service" ];
}

