{ config, lib, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi = {
        efiSysMountPoint = "/boot";
      };
    };
    initrd = {
      systemd.enable = true;
      availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" ];
      kernelModules = [ ];
      luks.devices."luks-bb43ada7-1451-490c-a783-12b79ade0911".device = "/dev/disk/by-uuid/bb43ada7-1451-490c-a783-12b79ade0911";
    };
    kernelModules = [ "kvm-amd" ];
    kernelParams = [ "reboot=bios" "nowatchdog" ]; # nvidia troubleshooting
    extraModulePackages = [ ];
  };

  fileSystems = {
    "/" =
      {
        device = "/dev/disk/by-uuid/4ccc8840-b037-47de-b47d-9153db65c5fa";
        fsType = "ext4";
      };

    "/boot" =
      {
        device = "/dev/disk/by-uuid/0658-3EC8";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };

    # Add bootloader entry for Bazzite here
    # "/boot/efi" = {
    #     device = "/dev/disk/by-uuid/YOUR-BAZZITE-EFI-UUID"; # nvme0n1p2
    #     fsType = "vfat";
    #     options = [ "nofail" ];
    #   };
  };

  security.tpm2 = {
    enable = true;
    pkcs11.enable = true;
    tctiEnvironment.enable = true;
  };

  networking.useDHCP = lib.mkDefault true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
