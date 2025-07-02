{ inputs, lib, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  boot.kernelParams = [ "kvm-amd" "kvm" "reboot=efi" ];
  boot.kernelModules = [ "r8152" "kvm-amd" "kvm" "reboot=efi" ];
  # boot.initrd.kernelModules = [ "reboot=efi" ];

  time.timeZone = "America/Los_Angeles";

  system.stateVersion = "23.11";
  services.journald.extraConfig = "SystemMaxUse=500M";

  # Mount tbay storage encryption keys
  systemd.tmpfiles.rules = lib.mkIf true [
    "d /mnt/thunderbay 0755 root root -"
    "d /mnt/thunderkey 0755 root root -"
  ];
  fileSystems."/mnt/thunderkey" = {
    device = "/dev/disk/by-label/thunderkey";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  systemd.services.docker = {
    # Wait for storage pool availability before starting docker...
    requires = [
      "mnt-thunderbay-2TB\\x2dE.mount"
      "mnt-thunderbay-4TB\\x2dB.mount"
      "mnt-thunderbay-8TB\\x2dA.mount"
      "mnt-thunderbay-8TB\\x2dC.mount"
      "mnt-thunderbay-8TB\\x2dD.mount"
    ];
  };

  # Onboard NIC for NixOS, 5Gb NIC for Incus bridge
  networking = {
    enableIPv6 = true;
    hostName = "barrel";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = false;
    useNetworkd = true;
    bridges.br1 = {
      interfaces = [ "enp7s0f3u4c2" ];
    };
    interfaces = {
      enp7s0f3u4c2.useDHCP = false;
      enp5s0.useDHCP = true;
      br1.useDHCP = true;
    };
  };

  # sops config - kept in host file while expirmenting with different implementation approaches
  sops = {
    defaultSopsFile = "/home/r6t/git/sops-ryan/secrets.yaml";
    age.keyFile = "/home/r6t/.config/sops/age/keys.txt";
    validateSopsFiles = false;
  };

  # Toggle modules
  mine = {
    home = {
      atuin.enable = true;
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
      ssh.enable = true;
    };

    alloy.enable = true;
    bootloader.enable = true;
    docker.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    incus.enable = true;
    libvirtd.enable = false;
    localization.enable = true;

    mountLuksStore = {
      barrelstore = {
        device = "/dev/disk/by-uuid/f6425279-658b-49bd-8c3a-1645b5936182";
        keyFile = "/root/barrelstore.key";
        mountPoint = "/mnt/barrelstore";
      };
      # drives from Thunderbay
      thunderbayA = {
        device = "/dev/disk/by-uuid/3c429d84-386d-4272-8739-7bd2dcde1159";
        keyFile = "/mnt/thunderkey/8tba";
        mountPoint = "/mnt/thunderbay/8TB-A";
      };
      thunderbayB = {
        device = "/dev/disk/by-uuid/b214dac6-7a73-4e53-9f89-b1ae82c0c625";
        keyFile = "/mnt/thunderkey/4tbe";
        mountPoint = "/mnt/thunderbay/4TB-B";
      };
      thunderbayC = {
        device = "/dev/disk/by-uuid/cb067a1e-147b-4052-b561-e2c16c31dd0e";
        keyFile = "/mnt/thunderkey/8tbd";
        mountPoint = "/mnt/thunderbay/8TB-C";
      };
      thunderbayD = {
        device = "/dev/disk/by-uuid/5b66a482-036d-4a76-8cec-6ad15fe2360c";
        keyFile = "/mnt/thunderkey/8tbb";
        mountPoint = "/mnt/thunderbay/8TB-D";
      };
      thunderbayE = {
        device = "/dev/disk/by-uuid/544de6c8-1332-47d2-a38f-ed67d4db46e4";
        keyFile = "/mnt/thunderkey/2tbf";
        mountPoint = "/mnt/thunderbay/2TB-E";
      };
    };

    nix.enable = true;
    nvidia-cuda.enable = true;
    prometheus-node-exporter.enable = true;
    rdfind.enable = true;
    sops.enable = true;
    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    tpm.enable = true;
    user.enable = true;
  };
}
