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
    kernel.sysctl = {
      # Router essentials
      "net.ipv4.conf.all.forwarding" = 1;
      # Disable IPv6 forwarding
      "net.ipv6.conf.all.forwarding" = 0;

      # Security hardening
      "net.ipv4.conf.all.rp_filter" = 2; # Loose mode for router/DHCP compatibility
      "net.ipv4.conf.all.accept_source_route" = 0;
      "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
      "net.ipv4.conf.all.log_martians" = 1;
    };
    # Enable IOMMU for NIC passthrough to Home Assistant
    kernelParams = [ "intel_iommu=on" "iommu=pt" ];
    kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];
  };

  networking = {
    # hostId = "5f3e2c0a";
    enableIPv6 = false;
    nat.enable = false;
    useNetworkd = true;
    hostName = "saguaro";
    dhcpcd.enable = false;
    nameservers = [ "127.0.0.1" ];

    interfaces = {
      # Intel I225-V NIC for router LAN (2.5G)
      enp100s0.useDHCP = false;
      # WAN interface gets DHCP from ISP
      enp101s0.useDHCP = true;
      # USB NIC for VM
      enp0s13f0u3c2.useDHCP = false;
    };

    firewall = {
      enable = false; # Disabled - using nftables instead
      checkReversePath = false;
    };
    nftables = {
      enable = true;
      ruleset = ''
        table inet filter {
          chain input {
            type filter hook input priority 0; policy drop;
            # Loopback always allowed
            iifname "lo" accept
            # DHCP from LAN (before conntrack)
            iifname "enp100s0" udp dport 67 accept
            # Established/related from anywhere
            ct state { established, related } accept
            ct state invalid drop
            # ICMP for diagnostics
            ip protocol icmp accept
            # SSH from LAN only
            iifname "enp100s0" tcp dport 22 accept
            # DNS from LAN only
            iifname "enp100s0" tcp dport 53 accept
            iifname "enp100s0" udp dport 53 accept
            # Incus from LAN
            iifname "enp100s0" tcp dport 8443 accept
          }
          chain output {
            type filter hook output priority 0; policy accept;
            # Allow all output from router (DHCP responses, DNS responses, updates, etc.)
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            ct state { established, related } accept
            ct state invalid drop
            # LAN -> WAN
            iifname "enp100s0" oifname "enp101s0" accept
          }
        }
        table ip nat {
          chain postrouting {
            type nat hook postrouting priority 100; policy accept;
            # Masquerade LAN traffic going to WAN
            oifname "enp101s0" masquerade
          }
        }
      '';
    };
  };
  nix.settings.use-cgroups = true;

  time.timeZone = "America/Los_Angeles";

  services = {
    journald.extraConfig = "SystemMaxUse=500M";

    resolved.enable = lib.mkForce false;

    dnsmasq = {
      enable = true;
      resolveLocalQueries = false;
      settings = {
        # Bind to interfaces as they come up (timing fix)
        bind-dynamic = true;

        # Explicit DNS listening addresses
        listen-address = [ "127.0.0.1" "192.168.6.1" ];

        address = [
          # specific overrides
          "/grafana.r6t.io/192.168.6.1"

          # wildcard so app LXCs hit router caddy
          "/r6t.io/192.168.6.1"
        ];

        # DHCP only on LAN interface
        interface = "enp100s0";

        # DNS Configuration only (DHCP handled by systemd-networkd)
        no-resolv = true;
        no-poll = true;
        cache-size = 10000;
        no-negcache = true;
        dns-forward-max = 1500;
        domain-needed = true;
        # Upstream DNS - NextDNS
        server = [ "127.0.0.1#5353" ];
      };
    };

    nextdns = {
      enable = true;
      arguments = [
        "-config-file"
        "/mnt/nextdns.conf"
        "-listen"
        "127.0.0.1:5353"
      ];
    };
  };

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
    network = {
      enable = true;
      # WAN interface - DHCP from ISP
      networks."10-wan" = {
        matchConfig.Name = "enp101s0";
        networkConfig = {
          DHCP = "ipv4";
        };
        linkConfig.RequiredForOnline = "routable";
      };

      # LAN interface - Intel I225-V 2.5G NIC
      networks."20-lan" = {
        matchConfig.Name = "enp100s0";
        address = [ "192.168.6.1/24" ];

        # Force interface UP and configured even without link/carrier
        networkConfig = {
          ConfigureWithoutCarrier = true;
          DHCPServer = true;
          LinkLocalAddressing = "ipv4";
        };
        linkConfig = {
          ActivationPolicy = "always-up";
          ARP = true;
        };

        # DHCP Server Configuration
        dhcpServerConfig = {
          PoolOffset = 11;
          PoolSize = 79; # 11-89
          DNS = [ "192.168.6.1" ];
          EmitRouter = true;
        };
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

    bootloader.enable = true;
    env.enable = true;
    fwupd.enable = true;
    iperf.enable = true;
    fzf.enable = true;
    incus.enable = true;
    localization.enable = true;
    mountLuksStore.kingston240 = { device = "/dev/disk/by-uuid/d7c2abad-2a6d-47ef-8310-dd57fb1156b9"; keyFile = "/root/kingston240key"; mountPoint = "/mnt/kingston240"; };
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
