# r6t's NixOS configuration: AMD CPU + Nvidia GPU desktop

{ config, lib, pkgs, ... }:

{
  imports =
    [
    #  <home-manager/nixos>
      inputs.home-manager.nixosModules.home-manager
      ./common-graphical.nix
      ./hardware-configuration.nix
    #  ./user.nix
    #  ./user-graphical.nix
    ];

  # Users:
  users.users.r6t = {
    isNormalUser = true;
    description = "r6t";
    extraGroups = [ "docker" "libvirtd" "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      # Import your home-manager configuration
      r6t = import ../home-manager/user-graphical.nix;
    };
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-592f29d8-cde7-4065-b38a-f0cd025e03fd".device = "/dev/disk/by-uuid/592f29d8-cde7-4065-b38a-f0cd025e03fd";
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ]; # sleep/wake

 # Nvidia GPU (unfree)
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # changed from default false
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
   };

  networking.hostName = "mountainball";

  nixpkgs.config.allowUnfree = true;

  services.xserver.videoDrivers = ["nvidia"];

  virtualisation.docker.enableNvidia = true;
}
