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
      "net.ipv6.conf.all.forwarding" = 1;

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

    interfaces = {
      # 10G Thunderbolt interface connects to switch
      LAN.useDHCP = false;
      # WAN interface gets DHCP from ISP
      enp2s0 = {
        useDHCP = true;
      };
      # NUC expansion NIC passed through to Home Assistant OS VM
      enp3s0.useDHCP = true;
    };

    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 22 443 ];
#      trustedInterfaces = [ "br1" "tailscale0" ];
    };
    nftables = {
      enable = true;
#      ruleset = ''
#        table inet filter {
#          # Flow offloading for performance
#          flowtable f {
#            hook ingress priority 0;
#            devices = { wan0, lan0 };
#          }
#
#          chain input {
#            type filter hook input priority filter; policy drop;
#            
#            # Loopback always allowed
#            iifname "lo" accept
#            
#            # Established/related from anywhere
#            ct state { established, related } accept
#            ct state invalid drop
#            
#            # ICMP for diagnostics
#            ip protocol icmp accept
#            ip6 nexthdr icmpv6 accept
#            
#            # SSH from LAN + Tailscale only
#            iifname { "lan0", "tailscale0" } tcp dport 22 accept
#            
#            # Headscale from WAN (HTTPS only)
#            iifname "wan0" tcp dport 443 ct state new accept
#            
#            # DNS from LAN + incusbr0
#            iifname { "lan0", "incusbr0" } tcp dport 53 accept
#            iifname { "lan0", "incusbr0" } udp dport 53 accept
#            
#            # DHCP from LAN + incusbr0
#            iifname { "lan0", "incusbr0" } udp dport 67 accept
#            
#            # Caddy from Tailscale + LAN ONLY (not WAN, not incusbr0)
#            iifname { "tailscale0", "lan0" } tcp dport { 80, 443 } accept
#            
#            # Log dropped packets (debugging)
#            # limit rate 5/minute log prefix "INPUT DROP: "
#          }
#
#          chain forward {
#            type filter hook forward priority filter; policy drop;
#            
#            # Flow offload established connections
#            ip protocol { tcp, udp } flow offload @f
#            
#            ct state { established, related } accept
#            ct state invalid drop
#            
#            # LAN -> WAN
#            iifname "lan0" oifname "wan0" accept
#            
#            # Tailscale -> LAN (for accessing services over 10G)
#            iifname "tailscale0" oifname "lan0" accept
#            
#            # Incus VMs/containers -> WAN (but NOT to router services)
#            iifname "incusbr0" oifname "wan0" accept
#            
#            # Block incusbr0 -> router host access (defense in depth)
#            iifname "incusbr0" oifname { "lan0", "tailscale0" } drop
#            
#            # Log dropped forwards (debugging)
#            # limit rate 5/minute log prefix "FORWARD DROP: "
#          }
#        }
#
#        table ip nat {
#          chain postrouting {
#            type nat hook postrouting priority srcnat; policy accept;
#            
#            # Masquerade LAN + Incus traffic going to WAN
#            oifname "wan0" masquerade
#          }
#        }
#      '';
    };
  };

  nix.settings.use-cgroups = true;

  time.timeZone = "America/Los_Angeles";

  services = {
    journald.extraConfig = "SystemMaxUse=500M";
    resolved = {
      enable = true;
      domains = [ "~." ];
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
    tmpfiles.rules = [
      "d /mnt/thunderbay 0755 root root -"
      "d /mnt/thunderkey 0755 root root -"
      "L /etc/caddy/Caddyfile - - - - /mnt/crownstore/Sync/app-config/caddy/crown.Caddyfile"
      "L /etc/caddy/caddy.env - - - - /mnt/crownstore/Sync/app-config/caddy/crown.caddy.env"
    ];
    services = {
      systemd-networkd-wait-online.enable = lib.mkForce false;
      nix-daemon.serviceConfig = {
        # Limit CPU usage to 50% for 16 vCPU
        # long builds (nvidia lxcs) impacted general service availability
        CPUQuota = "800%";
      };
    };
    # Reserve NIC device IDs
    #    network = {
    #      enable = true;
    #      # WAN interface - DHCP from ISP
    #      networks."10-wan" = {
    #        matchConfig.Name = "enp3s0";  # Your first 2.5G NIC
    #        networkConfig = {
    #          DHCP = "ipv4";
    #          IPv6AcceptRA = true;
    #        };
    #        linkConfig.RequiredForOnline = "routable";
    #      };
    #      
    #      # LAN interface - 10G to rack switch
    #      networks."20-lan" = {
    #        matchConfig.Name = "enp3s0";  # Your 10G NIC
    #        address = [ "192.168.6.1/24" ];
    #        networkConfig = {
    #          DHCPServer = true;
    #          IPv6SendRA = true;
    #        };
    #        dhcpServerConfig = {
    #          PoolOffset = 100;
    #          PoolSize = 100;
    #          DNS = [ "192.168.6.1" ];
    #        };
    #      };
    #      
    #      # Incus bridge (created by incus, just configure here)
    #      networks."30-incus" = {
    #        matchConfig.Name = "incusbr0";
    #        address = [ "10.0.100.1/24" ];
    #      };
    #    };

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
