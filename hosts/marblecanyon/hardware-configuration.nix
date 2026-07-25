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

  fileSystems."/" = {
    device = "/dev/disk/by-uuid/6a7ee72f-bb40-46ae-953b-5b41fbf202e2";
    fsType = "ext4";
  };

  boot.initrd.luks.devices."luks-9286e4ae-7db4-4ca1-8e9e-4bc04da2b067".device = "/dev/disk/by-uuid/9286e4ae-7db4-4ca1-8e9e-4bc04da2b067";

  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/7C37-B9AB";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
