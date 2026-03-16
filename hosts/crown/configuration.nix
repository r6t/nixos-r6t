{ inputs, lib, pkgs, ... }:

let
  allCaddyRoutes = import ../../containers/lib/caddy-routes.nix;

  # Containers whose caddy routes are served by crown's host caddy.
  # Includes spire-proxy: crown proxies pid.r6t.io to spire over tailnet
  # so LAN containers can reach PocketID without being on the tailnet.
  crownContainers = [
    "audiobookshelf"
    "changedetection"
    "immich"
    "it-tools"
    "jellyfin"
    "ladder"
    "llm"
    "miniflux"
    "ntfy"
    "paperless"
    "pirate-ship"
    "searxng"
    "spire-proxy"
    "sts"
  ];

  crownCaddyRoutes = lib.foldl' (acc: name: acc // allCaddyRoutes.${name}) { } crownContainers;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];


  boot = {
    kernel.sysctl = {
      # Enable forwarding for containers
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };
    kernelModules = [ "kvm-amd" "kvm" ];
    kernelParams = [ "kvm-amd" "kvm" "reboot=efi" ];
    supportedFilesystems = [ "zfs" ];
  };



  fileSystems."/mnt/thunderkey" = {
    device = "/dev/disk/by-label/thunderkey";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  networking = {
    hostId = "5f3e2c0a";
    nftables.enable = true; # Incus requires nftables
    enableIPv6 = true;
    useNetworkd = true;
    hostName = "crown";
    dhcpcd.enable = false;
    defaultGateway = {
      address = "192.168.6.1";
      interface = "enp1s0d1";
    };
    nameservers = [ "192.168.6.1" ];

    bridges = {
      br1 = { interfaces = [ "enp1s0" ]; };
    };

    interfaces = {
      enp1s0.useDHCP = false; # Bridge interface
      enp1s0d1 = {
        # Primary 10G interface
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.6.10";
          prefixLength = 24;
        }];
      };
      # 2.5G NICs for exit node passthrough (names pinned by MAC via udev)
      exit0.useDHCP = false;
      exit1.useDHCP = false;
      exit2.useDHCP = false;
      exit3.useDHCP = false;
      br1.useDHCP = true; # 10G bridge for Incus
    };

    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 22 443 8443 ];
      trustedInterfaces = [ "tailscale0" ];
    };
  };

  nix.settings.use-cgroups = true;

  time.timeZone = "America/Los_Angeles";

  services = {
    journald.extraConfig = "SystemMaxUse=500M";
    resolved = {
      enable = true;
      settings.Resolve.Domains = [ "~." ];
    };
  };

  system.stateVersion = "23.11";

  systemd.services = {

    tailscale-udp-gro = {
      description = "Enable UDP GRO forwarding for Tailscale on Mellanox interfaces";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      script = ''
        ${pkgs.ethtool}/bin/ethtool -K enp1s0d1 rx-udp-gro-forwarding on rx-gro-list off || true
        ${pkgs.ethtool}/bin/ethtool -K br1 rx-udp-gro-forwarding on rx-gro-list off || true
      '';

      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };
  };

  systemd = {
    # Pin 2.5G NIC names by PCI path for stable incus passthrough.
    # These are the 4 Intel I226-V ports passed to exit node containers.
    network.links = {
      "10-exit0" = { matchConfig.Path = "pci-0000:05:00.0"; linkConfig.Name = "exit0"; };
      "10-exit1" = { matchConfig.Path = "pci-0000:06:00.0"; linkConfig.Name = "exit1"; };
      "10-exit2" = { matchConfig.Path = "pci-0000:07:00.0"; linkConfig.Name = "exit2"; };
      "10-exit3" = { matchConfig.Path = "pci-0000:09:00.0"; linkConfig.Name = "exit3"; };
    };
    tmpfiles.rules = [
      "d /mnt/thunderbay 0755 root root -"
      "d /mnt/thunderkey 0755 root root -"
    ];
    services = {
      incus = {
        # Wait for storage pool before starting incus...
        requires = [ "mnt-crownstore.mount" ];
        after = [ "mnt-crownstore.mount" ];
        serviceConfig = {
          # ... and double check that it's there
          ExecStartPre = "${pkgs.coreutils}/bin/test -d /mnt/crownstore/incus";
        };
      };
      systemd-networkd-wait-online.enable = lib.mkForce false;
      nix-daemon.serviceConfig = {
        # Limit CPU usage to 50% for 16 vCPU
        # long builds (nvidia lxcs) impacted general service availability
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

    alloy.enable = true;
    incus-log-collector.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    caddy = {
      enable = true;
      environmentFile = "/mnt/crownstore/Sync/app-config/caddy/crown.caddy.env";
      routes = crownCaddyRoutes;
    };
    nixos-r6t-baseline.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    incus = {
      enable = true;
      profileDir = "/home/r6t/git/nixos-r6t/hosts/crown/incus-instances";
    };
    incus-nightly-rebuild = {
      enable = true;
      flakePath = "/home/r6t/git/nixos-r6t";
    };
    localization.enable = true;

    mountLuksStore = {
      crownstore = { device = "/dev/disk/by-uuid/f6425279-658b-49bd-8c3a-1645b5936182"; keyFile = "/root/crownstore.key"; mountPoint = "/mnt/crownstore"; };
      thunderbayA = { device = "/dev/disk/by-uuid/3c429d84-386d-4272-8739-7bd2dcde1159"; keyFile = "/root/3c429d84.key"; mountPoint = "/mnt/thunderbay/8TB-A"; };
      thunderbayC = { device = "/dev/disk/by-uuid/cb067a1e-147b-4052-b561-e2c16c31dd0e"; keyFile = "/root/cb067a1e.key"; mountPoint = "/mnt/thunderbay/8TB-C"; };
      thunderbayD = { device = "/dev/disk/by-uuid/5b66a482-036d-4a76-8cec-6ad15fe2360c"; keyFile = "/root/5b66a482.key"; mountPoint = "/mnt/thunderbay/8TB-D"; };
    };

    nix.enable = true;
    nvidia-cuda = {
      enable = true;
      package = "latest";
    };
    prometheus-node-exporter.enable = true;
    rdfind.enable = true;
    sops.enable = true;
    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;

    zfs-pool = {
      hdd-pool = {
        poolName = "hdd-pool";
        keyFile = "/mnt/thunderkey/hdd-pool.key";
        after = [ "mnt-thunderkey.mount" ];
        requires = [ "mnt-thunderkey.mount" ];

        delegation = {
          enableSend = true; # send snapshots without sudo
        };

        snapshots = {
          enable = true;

          daily = {
            enable = true;
            keep = 7;
            time = "02:00";
          };

          weekly = {
            enable = true;
            keep = 6;
            time = "03:00";
            dayOfWeek = "Sun";
          };

          monthly = {
            enable = true;
            keep = 36;
            time = "04:00";
            dayOfMonth = 1;
          };
        };
      };
    };
  };
}
