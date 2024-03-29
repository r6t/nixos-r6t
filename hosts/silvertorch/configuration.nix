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

    ../../modules/apps/docker/default.nix
    ../../modules/apps/flatpak/default.nix
    ../../modules/apps/hypr/default.nix
    ../../modules/apps/mullvad/default.nix
    ../../modules/apps/netdata/default.nix
    ../../modules/apps/ssh/default.nix
    ../../modules/apps/syncthing/default.nix
    ../../modules/apps/tailscale/default.nix
    ../../modules/apps/zsh/default.nix

    ../../modules/system/bluetooth/default.nix
    ../../modules/system/env/default.nix
    ../../modules/system/fonts/default.nix
    ../../modules/system/fwupd/default.nix
    ../../modules/system/localization/default.nix
    ../../modules/system/nix/default.nix
    ../../modules/system/nixpkgs/default.nix
    ../../modules/system/printing/default.nix
    ../../modules/system/sound/default.nix
  ];

  # apps modules
  mine.docker.enable = true;
  mine.flatpak.enable = true;
  mine.hypr.enable = true;
  mine.mullvad.enable = true;
  mine.netdata.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.zsh.enable = true;

  # system modules
  mine.bluetooth.enable = true;
  mine.env.enable = true;
  mine.fonts.enable = true;
  mine.fwupd.enable = true;
  mine.localization.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.printing.enable = true;
  mine.sound.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      # Import your home-manager configuration
      r6t = import ../../home-manager/home-graphical.nix;
    };
  };

  users.users = {
    r6t = {
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ ssh-keys.outPath ];
      # input group reqd for waybar
      extraGroups = [ "docker" "input" "networkmanager" "wheel"];
      shell = pkgs.zsh;
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-9fc9c182-0bad-474f-a9bb-ee2e6aa1be50".device = "/dev/disk/by-uuid/9fc9c182-0bad-474f-a9bb-ee2e6aa1be50";

  networking.hostName = "silvertorch";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "23.11";

}
