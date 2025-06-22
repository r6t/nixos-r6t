{ config, pkgs, lib, ... }:

{
  imports = [
    # Unused home-manager modules are a problem here so individual needed modules are called
    ../modules/nixos/alloy/default.nix
    ../modules/nixos/localization/default.nix
    ../modules/nixos/tailscale/default.nix
  ];

  boot.isContainer = true;
  networking.useHostResolvConf = false;
  system.stateVersion = "23.11";

  mine = {
    alloy.enable = true;
    localization.enable = true;
    tailscale.enable = true;
  };
}

