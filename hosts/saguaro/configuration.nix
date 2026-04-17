{ inputs, lib, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  boot = {
    # Enable IOMMU for NIC passthrough to Home Assistant
    kernelParams = [ "intel_iommu=on" "iommu=pt" ];
    kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
  };

  networking.hostName = "saguaro";
  nix.settings.use-cgroups = true;
  time.timeZone = "America/Los_Angeles";
  services.journald.extraConfig = "SystemMaxUse=500M";
  system.stateVersion = "23.11";

  systemd = {
    tmpfiles.rules = [ ];
    services = {
      # Storage-dependent services - wait for LUKS mount
      incus = {
        after = [ "mnt-kingston240.mount" ];
        requires = [ "mnt-kingston240.mount" ];
      };

      # System configuration
      systemd-networkd-wait-online.enable = lib.mkForce false;
      nix-daemon.serviceConfig = {
        CPUQuota = "800%";
      };
    };
  };

  # modules/
  mine = {
    home = {
      atuin.enable = true;
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
      ssh.enable = true;
    };

    alloy = {
      enable = true;
      lokiUrl = "https://loki.r6t.io/loki/api/v1/push";
      syslogListen = true;
    };
    home-router = {
      enable = true;
      cake.enable = true;
      healthCheck.enable = true;
      wanWatchdog.enable = true;
      lanAddress = "192.168.6.1/24";
      lanInterface = "enp100s0";
      wanInterface = "enp101s0";
      extraInterfaces = [
        "enp0s13f0u3c2" # USB NIC for Home Assistant VM
        "enp0s13f0u1c2" # USB NIC for LXC passthrough
      ];
      dhcpServer = {
        poolOffset = 11;
        poolSize = 79; # 11-89
        staticLeases = import ./ip-reservations.nix;
      };
      dns = {
        nextdnsConfigFile = "/mnt/nextdns.conf";
        # Route monitoring endpoints to crown's LAN IP so LAN clients
        # don't need tailnet access to push logs/metrics.
        dnsmasqAddresses = [ "/loki.r6t.io/192.168.6.10" ];
      };

      # Allow LAN to access the router host on specific ports
      nftablesAllowFromLan = {
        extraTcpPorts = [ 5201 8443 9000 9101 ]; # iperf3, incus, node-exporter, incus-metrics
        extraUdpPorts = [ 514 5201 ]; # syslog, iperf3
      };
    };

    bolt.enable = true;
    bootloader.enable = true;
    nixos-r6t-baseline.enable = true;
    fwupd.enable = true;
    iperf.enable = true;
    fzf.enable = true;
    incus = {
      enable = true;
      profileDir = "/home/r6t/git/nixos-r6t/hosts/saguaro/incus-instances";
    };
    localization.enable = true;
    mountLuksStore.kingston240 = {
      device = "/dev/disk/by-uuid/d7c2abad-2a6d-47ef-8310-dd57fb1156b9";
      keyFile = "/root/kingston240key";
      mountPoint = "/mnt/kingston240";
    };
    nix.enable = true;

    sops = {
      enable = true;
      defaultSopsFile = "/mnt/kingston240/sops-ryan/secrets.yaml";
      ageKeyFile = "/mnt/kingston240/age/keys.txt";
    };

    prometheus-node-exporter.enable = true;
    ssh.enable = true;
    user.enable = true;
  };
}
