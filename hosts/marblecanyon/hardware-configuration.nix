# Do not modify this file!  It follows the generated hardware-configuration.nix
# shape and can be replaced by nixos-generate-config after installation.
{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # Fedora reinstallation invalidated the previous NixOS disk UUIDs. Replace these
  # placeholders with a fresh nixos-generate-config result before installing.
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/REPLACE-ME-root";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-REPLACE-ME".device = "/dev/disk/by-uuid/REPLACE-ME-luks";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/REPLACE-ME-boot";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
