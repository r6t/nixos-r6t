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
    nat.enable = true;
    useNetworkd = true;
    hostName = "saguaro";
    dhcpcd.enable = false;

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
          # Flow offloading for performance
          flowtable f {
            hook ingress priority 0;
            devices = { enp101s0, enp4s0 };
          }
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
            # Caddy from Tailscale + LAN ONLY (not WAN, not incusbr0)
            iifname { "tailscale0", "enp4s0" } tcp dport { 80, 443 } accept
            # Log dropped packets (debugging)
            # limit rate 5/minute log prefix "INPUT DROP: "
          }
          chain forward {
            type filter hook forward priority 0; policy drop;
            # Flow offload established connections
            ip protocol { tcp, udp } flow offload @f
            ct state { established, related } accept
            ct state invalid drop
            # LAN -> WAN
            iifname "enp4s0" oifname "enp101s0" accept
            # Tailscale -> LAN (for accessing services over 10G)
            iifname "tailscale0" oifname "enp4s0" accept
            # Log dropped forwards (debugging)
            # limit rate 5/minute log prefix "FORWARD DROP: "
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
    dnsmasq = {
      enable = true;
      settings = {
        interface = "enp4s0";
        dhcp-range = "192.168.6.11,192.168.6.89,12h";
        dhcp-option = "option:router,192.168.6.1";
        # MAC reservations outside range, e.g.:
        # dhcp-host = "aa:bb:cc:dd:ee:ff,192.168.6.90";
      };
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
          networkConfig = {
            DHCPServer = true;
          };
          dhcpServerConfig = {
            PoolOffset = 11;
            PoolSize = 79; # 11-89
            DNS = [ "192.168.6.1" ];
          };
        };
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
    headscale.enable = true;
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
