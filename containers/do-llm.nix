{ config, pkgs, lib, ... }:
{
  imports = [
    ./r6-lxc-base.nix
    ../modules/nixos/immich/default.nix
  ];

  networking.hostName = "immich";

  mine.immich.enable = true;

}

