{ inputs, lib, pkgs, ... }:

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
      "net.ipv4.conf.all.rp_filter" = 1;
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
      # 10G Thunderbolt interface connects to switch (LAN)
      enp4s0.useDHCP = false;
      # WAN interface gets DHCP from ISP
      enp101s0.useDHCP = true;
    };

    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 22 443 ];
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
            # Established/related from anywhere
            ct state { established, related } accept
            ct state invalid drop
            # ICMP for diagnostics
            ip protocol icmp accept
            # SSH from LAN + Tailscale only
            iifname { "enp4s0", "tailscale0" } tcp dport 22 accept
            # Headscale from WAN (HTTPS only)
            iifname "enp101s0" tcp dport 443 ct state new accept
            # DNS from LAN
            iifname "enp4s0" tcp dport 53 accept
            iifname "enp4s0" udp dport 53 accept
            # DHCP from LAN
            iifname "enp4s0" udp dport 67 accept
            # Caddy from Tailscale + LAN ONLY
            iifname { "tailscale0", "enp4s0" } tcp dport { 80, 443 } accept
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            ct state { established, related } accept
            ct state invalid drop
            # LAN -> WAN
            iifname "enp4s0" oifname "enp101s0" accept
            # Tailscale -> LAN (for accessing services over 10G)
            iifname "tailscale0" oifname "enp4s0" accept
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
        interface = "enp4s0";
        dhcp-range = "192.168.6.11,192.168.6.89,12h";
        dhcp-option = [
          "option:router,192.168.6.1"
          "option:dns-server,192.168.6.1"
        ];

        # DNS Configuration
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

        # MAC/IP reservations
        dhcp-host = import ./ip-reservations.nix;
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
      "d /mnt/thunderbay 0755 root root -"
      "d /mnt/thunderkey 0755 root root -"
      "L /etc/caddy/Caddyfile - - - - /mnt/crownstore/Sync/app-config/caddy/crown.Caddyfile"
      "L /etc/caddy/caddy.env - - - - /mnt/crownstore/Sync/app-config/caddy/crown.caddy.env"
    ];
    services = {
      systemd-networkd-wait-online.enable = lib.mkForce false;
      nix-daemon.serviceConfig = {
        CPUQuota = "800%";
      };

      # Ensure dnsmasq waits for network to be configured
      dnsmasq = {
        after = [ "systemd-networkd.service" ];
        wants = [ "systemd-networkd.service" ];
      };

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

      # LAN interface - 10G to rack switch
      networks."20-lan" = {
        matchConfig.Name = "enp4s0";
        address = [ "192.168.6.1/24" ];
      };
    };
    #      "10-enp5s0" = { matchConfig.Path = "pci-0000:05:00.0"; linkConfig.Name = "enp5s0"; };
    #      "10-enp6s0" = { matchConfig.Path = "pci-0000:06:00.0"; linkConfig.Name = "enp6s0"; };
    #      "10-enp7s0" = { matchConfig.Path = "pci-0000:07:00.0"; linkConfig.Name = "enp7s0"; };
    #      "10-enp8s0" = { matchConfig.Path = "pci-0000:09:00.0"; linkConfig.Name = "enp8s0"; };
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
    caddy.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    incus.enable = true;
    localization.enable = true;
    nix.enable = true;
    rdfind.enable = true;
    sops.enable = true;
    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;
  };
}
