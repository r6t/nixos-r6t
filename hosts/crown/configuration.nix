{ inputs, lib, pkgs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  boot.kernelParams = [ "kvm-amd" "kvm" "reboot=efi" ];
  boot.kernelModules = [ "kvm-amd" "kvm" "reboot=efi" ]; # "r8152" for Realtek USB3 5Gb NIC dongle
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
    # Wait for storage pool availability before starting docker.
    requires = [
      "mnt-thunderbay-4TB\\x2dB.mount"
      "mnt-thunderbay-8TB\\x2dA.mount"
      "mnt-thunderbay-8TB\\x2dC.mount"
      "mnt-thunderbay-8TB\\x2dD.mount"
    ];
  };

  # Storage path patch for old workloads... I need more NVME slots!
  systemd.mounts = [
    {
      what = "/mnt/crownstore/tbay2TB-E";
      # Nix will generate name 'mnt-thunderbay-2TB\x2dE.mount'
      where = "/mnt/thunderbay/2TB-E";
      type = "none";
      options = "bind";
      requires = [ "mnt-crownstore.mount" ];
      before = [ "docker.service" "incus.service" ];
      wantedBy = [ "multi-user.target" ];
    }
  ];

  # Temporary old docker settings. The module had some personal bare-metal specifics and is changing to be used in LXC + AMI builds too. I plan to eventually run everything that's been running in docker containers on a linux host (aka homelab services) in individual LXCs instead.
  virtualisation.docker.daemon.settings = {
    ipv6 = true;
    data-root = "/home/r6t/docker-root/";
    fixed-cidr-v6 = "fdcb:ab14:ad77::/64";
  };

  # Onboard NIC for NixOS, 5Gb NIC for Incus bridge
  networking = {
    enableIPv6 = true;
    hostName = "crown";
    useDHCP = lib.mkDefault true;
    networkmanager.enable = false;
    useNetworkd = true;
    bridges.br1 = {
      interfaces = [ "enp7s0" ];
    };
    interfaces = {
      enp1s0.useDHCP = false;
      enp1s0d1.useDHCP = false;
      enp5s0.useDHCP = true;
      enp6s0.useDHCP = true;
      enp7s0.useDHCP = false;
      enp8s0.useDHCP = true;
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
    caddy.enable = false;
    docker.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    incus.enable = true;
    libvirtd.enable = false;
    localization.enable = true;

    mountLuksStore = {
      crownstore = {
        device = "/dev/disk/by-uuid/f6425279-658b-49bd-8c3a-1645b5936182";
        keyFile = "/root/crownstore.key";
        mountPoint = "/mnt/crownstore";
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
      # thunderbayE = {
      #   device     = "/dev/disk/by-uuid/544de6c8-1332-47d2-a38f-ed67d4db46e4";
      #   keyFile    = "/mnt/thunderkey/2tbf";
      #   mountPoint = "/mnt/thunderbay/2TB-E";
      # }; 
    };

    nix.enable = true;
    nvidia-cuda.enable = false;
    prometheus-node-exporter.enable = false;
    rdfind.enable = true;
    sops.enable = false;
    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    tpm.enable = false;
    user.enable = true;
  };
}
