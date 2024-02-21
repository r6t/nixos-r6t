# r6t's NixOS configuration: 13" Framework AMD laptop

{ config, lib, pkgs, ... }:

{
  imports =
    [
      <home-manager/nixos>
      <nixos-hardware/framework/13-inch/7040-amd>
      ./common-graphical.nix
      ./hardware-configuration.nix
      ./user.nix
      ./user-graphical.nix
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-9fc9c182-0bad-474f-a9bb-ee2e6aa1be50".device = "/dev/disk/by-uuid/9fc9c182-0bad-474f-a9bb-ee2e6aa1be50";

  networking.hostName = "silvertorch"; # Define your hostname.
}
