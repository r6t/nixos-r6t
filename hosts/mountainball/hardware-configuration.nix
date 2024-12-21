{ config, lib, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot = {
    initrd = {
      availableKernelModules = [ "nvme" "xhci_pci" "thunderbolt" "usb_storage" "sd_mod" ];
      kernelModules = [ ];
      luks.devices."luks-82d23557-c346-40df-8152-ea991855ccf2".device = "/dev/disk/by-uuid/82d23557-c346-40df-8152-ea991855ccf2";
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/fe49ac97-195e-408f-b0e9-a60443c95074";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/A064-C94F";
      fsType = "vfat";
    };
  };

  swapDevices = [{ device = "/dev/disk/by-uuid/2d428f09-3a6b-4934-a16f-884359cba287"; }];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}

