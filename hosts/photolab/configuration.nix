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
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # system details
  networking.hostName = "photolab";
  networking.firewall.allowedTCPPorts = [ 
    22
    2283 # immich
    3389 # VM RDP
    8384
    22000
    ];
  networking.firewall.allowedUDPPorts = [ 
    ];
  networking = {
    enableIPv6 = true;
  };

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = true;
    "net.ipv6.conf.all.forwarding" = true;
  };

  system.stateVersion = "23.11";
  
  # Boot options for KVM with EGPU passthrough
  # boot.blacklistedKernelModules = [ "nvidia" "nouveau" ];
  # boot.extraModprobeConfig = ''
  #   options vfio-pci ids=10de:1b82,10de:10f0,8086:15d3
  # '';
  # boot.kernelModules = [ "kvm-intel" "vfio_virqfd" "vfio" "vfio_pci" "vfio_iommu_type1" ];
  # boot.kernelParams = [ "intel_iommu=on" ];

  # users.users.r6t.linger = true;

  # system modules
  mine.bolt.enable = true;
  mine.bootloader.enable = true;
  mine.bridge.enable = false;
  mine.docker.enable = true;
  mine.env.enable = true;
  mine.fwupd.enable = true;
  mine.libvirtd.enable = false;
  mine.localization.enable = true;
  mine.netdata.enable = true;
  mine.networkmanager.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.nvidia.enable = true;
  mine.selfhost.enable = false;
  mine.sops.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.thunderbay.enable = false;
  mine.user.enable = true;
  mine.zsh.enable = true;

  # home modules
  mine.home.awscli.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.nixvim.enable = true;
  mine.home.python3.enable = true;
  mine.home.zsh.enable = true;
}
