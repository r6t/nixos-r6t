{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}:

let
  inherit (inputs) ssh-keys;
in
 {
  # You can import other NixOS modules here
  imports = [
    inputs.home-manager.nixosModules.home-manager

    # Hardware list: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
    inputs.hardware.nixosModules.framework-13-7040-amd

    ./hardware-configuration.nix
    ../../modules/nixos/apps/docker/default.nix
    ../../modules/nixos/apps/hypr/default.nix
    ../../modules/nixos/apps/syncthing/default.nix
    ../../modules/nixos/system/bluetooth/default.nix
    ../../modules/nixos/system/env/default.nix
    ../../modules/nixos/system/fonts/default.nix
    ../../modules/nixos/system/localization/default.nix
    ../../modules/nixos/system/nix/default.nix
    ../../modules/nixos/system/nixpkgs/default.nix
    ../../modules/nixos/system/sound/default.nix
  ];

  mine.bluetooth.enable = true;
  mine.docker.enable = true;
  mine.env.enable = true;
  mine.fonts.enable = true;
  mine.hypr.enable = true;
  mine.localization.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.sound.enable = true;
  mine.syncthing.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      # Import your home-manager configuration
      r6t = import ../../home-manager/home-graphical.nix;
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-9fc9c182-0bad-474f-a9bb-ee2e6aa1be50".device = "/dev/disk/by-uuid/9fc9c182-0bad-474f-a9bb-ee2e6aa1be50";

  networking.hostName = "silvertorch";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  programs.zsh.enable = true;

  services.fwupd.enable = true; # Linux firmware updater

  services.printing.enable = true; # CUPS print support

  services.tailscale.enable = true;



  system.stateVersion = "23.11";

  users.users = {
    r6t = {
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ ssh-keys.outPath ];
      # input group reqd for waybar
      extraGroups = [ "docker" "input" "networkmanager" "wheel"];
      shell = pkgs.zsh;
    };
  };
}
