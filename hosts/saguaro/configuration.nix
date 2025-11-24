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
      # 8123 for home assistant
      # 8384 for syncthing temp
      # 8443 for incus temporarily
      allowedTCPPorts = [ 22 443 8123 8384 8443 ];
      #      trustedInterfaces = [ "br1" "tailscale0" ];
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
            # SSH from LAN + Tailscale only
            iifname { "enp100s0", "tailscale0" } tcp dport 22 accept
            # Headscale from WAN (HTTPS only)
            iifname "enp101s0" tcp dport 443 ct state new accept
            # DNS from LAN
            iifname "enp100s0" tcp dport 53 accept
            iifname "enp100s0" udp dport 53 accept
            # Home Assistant from LAN
            iifname "enp100s0" tcp dport 8123 accept
            # Syncthing from LAN
            iifname "enp100s0" tcp dport { 8384, 22000 } accept
            # Incus from LAN
            iifname "enp100s0" tcp dport 8443 accept
            # Caddy from Tailscale + LAN ONLY
            iifname { "tailscale0", "enp100s0" } tcp dport { 80, 443 } accept
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
            # Tailscale -> LAN
            iifname "tailscale0" oifname "enp100s0" accept
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

        # DHCP only on LAN interface
        interface = "enp100s0";

        # DNS Configuration only (DHCP handled by systemd-networkd)
        no-resolv = true;
        no-poll = true;
        cache-size = 10000;
        no-negcache = true;
        dns-forward-max = 1500;
        domain-needed = true;

        # Local DNS overrides (hairpin NAT avoidance)
        address = import ./dns-overrides.nix;

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
    tmpfiles.rules = [
    ];
    services = {
      caddy = {
        after = [ "mnt-kingston240.mount" ];
        requires = [ "mnt-kingston240.mount" ];
      };

      incus = {
        after = [ "mnt-kingston240.mount" ];
        requires = [ "mnt-kingston240.mount" ];
      };

      headscale = {
        after = [ "caddy.service" ];
        requires = [ "caddy.service" ];
      };

      tailscale = {
        after = [ "systemd-networkd.service" "dnsmasq.service" "headscale.service" ];
        requires = [ "systemd-networkd.service" "dnsmasq.service" "headscale.service" ];
      };

      syncthing = {
        after = [ "tailscale.service" ];
        requires = [ "tailscale.service" ];
      };

      router-services-check = {
        description = "Check that all router services are running";
        after = [ "caddy.service" "incus.service" "headscale.service" "tailscale.service" "syncthing.service" "nextdns.service" "dnsmasq.service" "nftables.service" ];
        requires = [ "caddy.service" "incus.service" "headscale.service" "tailscale.service" "syncthing.service" "nextdns.service" "dnsmasq.service" "nftables.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.systemd}/bin/systemctl is-active caddy incus headscale tailscale syncthing nextdns dnsmasq nftables";
          RemainAfterExit = true;
        };
      };

      systemd-networkd-wait-online.enable = lib.mkForce false;
      nix-daemon.serviceConfig = {
        CPUQuota = "800%";
      };

      # Ensure dnsmasq waits for network to be configured
      dnsmasq = {
        after = [ "systemd-networkd.service" ];
        wants = [ "systemd-networkd.service" ];
      };

      nextdns = {
        after = [ "systemd-networkd.service" ];
        requires = [ "systemd-networkd.service" ];
      };

      nftables = {
        after = [ "systemd-networkd.service" ];
        requires = [ "systemd-networkd.service" ];
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

    alloy.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    caddy = {
      enable = true;
      configFile = "/mnt/kingston240/caddy/Caddyfile";
      environmentFile = "/mnt/kingston240/caddy/caddy.env";
    };
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;

    headscale = {
      enable = true;
      serverUrl = "https://headscale.r6t.io";
      baseDomain = "r6.internal";
    };

    iperf.enable = true;
    incus.enable = true;
    localization.enable = true;
    mountLuksStore.kingston240 = { device = "/dev/disk/by-uuid/d7c2abad-2a6d-47ef-8310-dd57fb1156b9"; keyFile = "/root/kingston240key"; mountPoint = "/mnt/kingston240"; };
    nix.enable = true;
    rdfind.enable = true;

    sops = {
      enable = true;
      defaultSopsFile = "/mnt/kingston240/sops-ryan/secrets.yaml";
      ageKeyFile = "/mnt/kingston240/age/keys.txt";
    };

    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;
  };
}
