{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}:

 {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.hardware.nixosModules.raspberry-pi-4

    ./hardware-configuration.nix
    ../../modules/default.nix
  ];
 
  boot.loader.grub.enable = false;
  boot.loader.generic-extlinux-compatible.enable = true;

  hardware = {
    raspberry-pi."4".apply-overlays-dtmerge.enable = true;
    deviceTree = {
      enable = true;
      filter = "*rpi-4-*.dtb";
    };
  };

  console.enable = false;

  environment.systemPackages = with pkgs; [
    libraspberrypi
    raspberrypi-eeprom
  ];
  # system details
  networking.hostName = "mv-exit-node";
  networking.firewall.allowedTCPPorts = [ 
    22
    8384
    22000
    ];
  networking.firewall.allowedUDPPorts = [ 
    ];
  system.stateVersion = "24.11";
  
  # Boot options for KVM with EGPU passthrough
  # boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];
  # boot.extraModprobeConfig = ''
  #   options vfio-pci ids=10de:1b82,10de:10f0,8086:15d3
  # '';
  # boot.kernelModules = [ "kvm-intel" "vfio_virqfd" "vfio" "vfio_pci" "vfio_iommu_type1" ];
  # boot.kernelParams = [ "intel_iommu=on" ];

  # users.users.r6t.linger = true;

  # system modules
  mine.sops.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.user.enable = true;
  mine.zsh.enable = true;

  # home modules
  mine.home.awscli.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.python3.enable = true;
  mine.home.zsh.enable = true;
}
