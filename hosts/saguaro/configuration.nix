{ lib, ... }:

let
  lanInterface = "enp100s0";
  wanInterface = "enp101s0";
in

{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/mountLuksStore/options.nix
    ../../modules/nixos/mountLuksStore/config.nix
  ];

  boot = {
    # Enable IOMMU for NIC passthrough to Home Assistant
    kernelParams = [ "intel_iommu=on" "iommu=pt" ];
    kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
  };

  networking = {
    hostName = "saguaro";
    extraHosts = ''
      192.168.6.10 loki.r6t.io
    '';
  };
  system.stateVersion = "23.11";

  services = {
    alloy.extraFlags = lib.mkForce [
      "--server.http.listen-addr=192.168.6.1:12346"
      "--disable-reporting"
    ];
    prometheus.exporters.node.listenAddress = "192.168.6.1";
  };

  virtualisation.incus.preseed = {
    config = {
      "core.https_address" = "192.168.6.1:8443";
      "core.metrics_address" = "192.168.6.1:9101";
      "core.metrics_authentication" = "false";
    };
  };

  systemd = {
    network.links = {
      # Pin router port names by PCI path. Avoid MAC matches because this flake is public.
      "10-saguaro-lan" = {
        matchConfig.Path = "pci-0000:64:00.0";
        linkConfig.Name = lanInterface;
      };
      "10-saguaro-wan" = {
        matchConfig.Path = "pci-0000:65:00.0";
        linkConfig.Name = wanInterface;
      };
    };

    services = {
      # Storage-dependent services - wait for LUKS mount
      incus = {
        after = [ "mnt-kingston240.mount" ];
        requires = [ "mnt-kingston240.mount" ];
      };
    };
  };

  # modules/
  mine = {
    home-router = {
      lanAddress = "192.168.6.1/24";
      inherit lanInterface wanInterface;
      dhcpServer = {
        poolOffset = 11;
        poolSize = 79; # 11-89
        staticLeases = import ./ip-reservations.nix;
      };
      dns = {
        nextdnsConfigFile = "/mnt/nextdns.conf";
        # Monitoring endpoints use the tailnet path for encryption between
        # LAN devices (like mountainball -> crown). Saguaro uses a private
        # short-circuit in networking.extraHosts above.
        dnsmasqAddresses = [ ];
      };

      # Allow LAN to access the router host on specific ports
      nftablesAllowFromLan = {
        extraTcpPorts = [ 5201 8443 ]; # iperf3, incus API/UI
        extraUdpPorts = [ 514 5201 ]; # syslog, iperf3
        sourceTcpPorts = [
          { source = "192.168.6.3"; ports = [ 9000 9101 12346 ]; } # spire monitoring
        ];
      };
    };

    incus.profileDir = "/home/r6t/git/nixos-r6t/hosts/saguaro/incus-instances";

    mountLuksStore.kingston240 = {
      device = "/dev/disk/by-uuid/d7c2abad-2a6d-47ef-8310-dd57fb1156b9";
      keyFile = "/root/kingston240key";
      mountPoint = "/mnt/kingston240";
    };

    sops = {
      defaultSopsFile = "/mnt/kingston240/sops-ryan/secrets.yaml";
      ageKeyFile = "/mnt/kingston240/age/keys.txt";
    };
  };
}
