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

    home-router = {
      enable = true;
      cake.enable = true;
      lanAddress = "192.168.6.1/24";
      lanInterface = "enp100s0";
      wanInterface = "enp101s0";
      extraInterfaces = [ "enp0s13f0u3c2" ]; # USB NIC for VM
      dhcpServer = {
        poolOffset = 11;
        poolSize = 79; # 11-89
      };
      dns = {
        # Uncomment/add DNS overrides as needed:
        # dnsmasqAddresses = [
        #   "/crown/192.168.6.10"
        #   "/grafana.r6t.io/192.168.6.1"
        #   "/homeassistant.r6t.io/100.124.208.128"
        #   "/saguaro/192.168.6.1"
        #   "/r6t.io/192.168.6.10"
        # ];
        nextdnsConfigFile = "/mnt/nextdns.conf";
      };

      # Allow LAN to access the router host on specific ports
      nftablesAllowFromLan = {
        extraTcpPorts = [ 5201 8443 ]; # iperf3, incus
        extraUdpPorts = [ 5201 ]; # iperf3
      };
    };

    bootloader.enable = true;
    nixos-r6t-baseline.enable = true;
    fwupd.enable = true;
    iperf.enable = true;
    fzf.enable = true;
    incus.enable = true;
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

    ssh.enable = true;
    user.enable = true;
  };
}
