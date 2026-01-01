{ lib, config, pkgs, ... }:

let
  cfg = config.mine.home-router;
in
{
  options.mine.home-router = {
    enable = lib.mkEnableOption "home router with CAKE QoS for bufferbloat mitigation";

    # Network interfaces
    wanInterface = lib.mkOption {
      type = lib.types.str;
      default = "enp101s0";
      description = "WAN interface name (connected to ISP)";
    };

    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "enp100s0";
      description = "LAN interface name (internal network)";
    };

    extraInterfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [ "enp0s13f0u3c2" ];
      description = "Additional interfaces to configure (e.g., VM NICs)";
    };

    # LAN network configuration
    lanAddress = lib.mkOption {
      type = lib.types.str;
      default = "192.168.6.1/24";
      description = "LAN IP address with CIDR notation";
    };

    lanGatewayIP = lib.mkOption {
      type = lib.types.str;
      default = builtins.head (lib.splitString "/" cfg.lanAddress);
      defaultText = "First part of lanAddress";
      description = "LAN gateway IP (derived from lanAddress by default)";
    };

    # DHCP server configuration
    dhcpServer = {
      poolOffset = lib.mkOption {
        type = lib.types.int;
        default = 11;
        description = "DHCP pool starting offset from network base";
      };

      poolSize = lib.mkOption {
        type = lib.types.int;
        default = 79;
        description = "Number of DHCP addresses in pool";
      };
    };

    # DNS configuration
    dns = {
      dnsmasqAddresses = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        example = [
          "/hostname/192.168.6.10"
          "/example.com/192.168.6.20"
        ];
        description = "DNS address overrides for dnsmasq";
      };

      upstreamServer = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1#5353";
        description = "Upstream DNS server for dnsmasq";
      };

      nextdnsConfigFile = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = "/mnt/storage/nextdns.conf";
        description = "Path to NextDNS configuration file (null to disable NextDNS)";
      };
    };

    # nftables configuration - LAN-only access
    nftablesAllowFromLan = {
      extraTcpPorts = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
        example = [ 5201 8443 ];
        description = "Extra TCP ports to allow from LAN only (NOT exposed to WAN)";
      };

      extraUdpPorts = lib.mkOption {
        type = lib.types.listOf lib.types.int;
        default = [ ];
        example = [ 5201 ];
        description = "Extra UDP ports to allow from LAN only (NOT exposed to WAN)";
      };
    };

    # CAKE QoS configuration
    cake = {
      enable = lib.mkEnableOption "CAKE QoS for bufferbloat mitigation" // { default = true; };

      downloadRate = lib.mkOption {
        type = lib.types.int;
        default = 970000; # kbit - 970 Mbps for gigabit fiber
        description = "Download rate limit in kbit (leave ~3% headroom for queue management)";
      };

      uploadRate = lib.mkOption {
        type = lib.types.int;
        default = 970000; # kbit - 970 Mbps for gigabit fiber
        description = "Upload rate limit in kbit (leave ~3% headroom for queue management)";
      };

      overhead = lib.mkOption {
        type = lib.types.int;
        default = 18; # Ethernet framing only (no PPPoE)
        description = "Link layer overhead in bytes (18 for fiber without PPPoE, 26 with PPPoE)";
      };

      extraOptions = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [
          "diffserv4" # 4-tier traffic prioritization (better for gaming)
          "dual-srchost" # Fair queuing per source IP
          "nat" # Recognize NATed devices individually
          "nowash" # Don't reclassify DSCP markings
          "ack-filter" # Filter redundant ACKs during upload saturation
        ];
        description = "Additional CAKE qdisc options";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure iproute2 with CAKE support is available
    environment.systemPackages = with pkgs; [
      iproute2
      ethtool
    ];

    # Router kernel configuration
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
      kernelModules = lib.mkIf cfg.cake.enable [ "sch_cake" "ifb" "act_mirred" ];
    };

    # Network configuration
    networking = {
      enableIPv6 = false;
      nat.enable = false;
      useNetworkd = true;
      dhcpcd.enable = false;
      nameservers = [ "127.0.0.1" ];

      interfaces = {
        ${cfg.lanInterface}.useDHCP = false;
        ${cfg.wanInterface}.useDHCP = true;
      } // lib.listToAttrs (map
        (iface: {
          name = iface;
          value.useDHCP = false;
        })
        cfg.extraInterfaces);

      firewall = {
        enable = false; # Disabled - using nftables instead
        checkReversePath = false;
      };

      nftables =
        let
          # Generate extra TCP port rules (LAN-only)
          extraTcpRules = lib.concatMapStringsSep "\n"
            (port: ''
              iifname "${cfg.lanInterface}" tcp dport ${toString port} accept
            '')
            cfg.nftablesAllowFromLan.extraTcpPorts;

          # Generate extra UDP port rules (LAN-only)
          extraUdpRules = lib.concatMapStringsSep "\n"
            (port: ''
              iifname "${cfg.lanInterface}" udp dport ${toString port} accept
            '')
            cfg.nftablesAllowFromLan.extraUdpPorts;
        in
        {
          enable = true;
          ruleset = ''
            table inet filter {
              chain input {
                type filter hook input priority 0; policy drop;
                # Loopback always allowed
                iifname "lo" accept

                # DHCP from LAN (before conntrack)
                iifname "${cfg.lanInterface}" udp dport 67 accept

                # Established/related connections (return traffic for outbound connections)
                ct state { established, related } accept

                # Invalid packets - log and drop
                ct state invalid log prefix "INVALID-PKT: " drop

                # Explicitly drop NEW connections from WAN (defense in depth)
                iifname "${cfg.wanInterface}" ct state new log prefix "WAN-INPUT-DROP: " drop

                # ICMP from LAN only (no WAN ping)
                iifname "${cfg.lanInterface}" ip protocol icmp accept

                # SSH from LAN only
                iifname "${cfg.lanInterface}" tcp dport 22 accept

                # DNS from LAN only
                iifname "${cfg.lanInterface}" tcp dport 53 accept
                iifname "${cfg.lanInterface}" udp dport 53 accept

                # Extra ports from LAN only
                ${extraTcpRules}
                ${extraUdpRules}
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
                iifname "${cfg.lanInterface}" oifname "${cfg.wanInterface}" accept
              }
            }
            table ip nat {
              chain postrouting {
                type nat hook postrouting priority 100; policy accept;
                # Masquerade LAN traffic going to WAN
                oifname "${cfg.wanInterface}" masquerade
              }
            }
          '';
        };
    };

    # DNS and DHCP services
    services = {
      resolved.enable = lib.mkForce false;

      dnsmasq = {
        enable = true;
        resolveLocalQueries = false;
        settings = {
          # Bind to interfaces as they come up (timing fix)
          bind-dynamic = true;

          # Explicit DNS listening addresses
          listen-address = [ "127.0.0.1" cfg.lanGatewayIP ];

          # DNS address overrides
          address = cfg.dns.dnsmasqAddresses;

          # DHCP only on LAN interface
          interface = cfg.lanInterface;

          # DNS Configuration only (DHCP handled by systemd-networkd)
          no-resolv = true;
          no-poll = true;
          cache-size = 10000;
          no-negcache = true;
          dns-forward-max = 1500;
          domain-needed = true;

          # Upstream DNS server
          server = [ cfg.dns.upstreamServer ];
        };
      };

      nextdns = lib.mkIf (cfg.dns.nextdnsConfigFile != null) {
        enable = true;
        arguments = [
          "-config-file"
          cfg.dns.nextdnsConfigFile
          "-listen"
          "127.0.0.1:5353"
        ];
      };
    };

    # systemd-networkd configuration
    systemd.network = {
      enable = true;

      # WAN interface - DHCP from ISP
      networks."10-wan" = {
        matchConfig.Name = cfg.wanInterface;
        networkConfig = {
          DHCP = "ipv4";
        };
        linkConfig.RequiredForOnline = "routable";
      };

      # LAN interface
      networks."20-lan" = {
        matchConfig.Name = cfg.lanInterface;
        address = [ cfg.lanAddress ];

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
          PoolOffset = cfg.dhcpServer.poolOffset;
          PoolSize = cfg.dhcpServer.poolSize;
          DNS = [ cfg.lanGatewayIP ];
          EmitRouter = true;
        };
      };
    };

    # CAKE QoS services
    systemd.services = lib.mkIf cfg.cake.enable {
      cake-qos-egress = {
        description = "CAKE QoS egress (upload) shaping on ${cfg.wanInterface}";
        after = [ "systemd-networkd.service" "network-online.target" ];
        wants = [ "network-online.target" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          # Wait for interface to be ready
          for i in {1..30}; do
            if ${pkgs.iproute2}/bin/ip link show ${cfg.wanInterface} &>/dev/null; then
              break
            fi
            sleep 1
          done

          # Remove existing qdisc (ignore errors if none exists)
          ${pkgs.iproute2}/bin/tc qdisc del dev ${cfg.wanInterface} root 2>/dev/null || true

          # Apply CAKE to WAN egress (upload)
          ${pkgs.iproute2}/bin/tc qdisc add dev ${cfg.wanInterface} root cake \
            bandwidth ${toString cfg.cake.uploadRate}kbit \
            ${lib.concatStringsSep " " cfg.cake.extraOptions} \
            ethernet \
            overhead ${toString cfg.cake.overhead}

          echo "CAKE egress (upload) applied to ${cfg.wanInterface}: ${toString cfg.cake.uploadRate} kbit"
        '';

        preStop = ''
          # Restore default qdisc on service stop
          ${pkgs.iproute2}/bin/tc qdisc del dev ${cfg.wanInterface} root 2>/dev/null || true
          echo "CAKE egress removed from ${cfg.wanInterface}"
        '';
      };

      cake-qos-ingress = {
        description = "CAKE QoS ingress (download) shaping on ${cfg.wanInterface} via IFB";
        after = [ "cake-qos-egress.service" ];
        wants = [ "cake-qos-egress.service" ];
        wantedBy = [ "multi-user.target" ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        script = ''
          # Create IFB (Intermediate Functional Block) interface for ingress shaping
          ${pkgs.iproute2}/bin/ip link add ifb4${cfg.wanInterface} type ifb 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip link set ifb4${cfg.wanInterface} up

          # Redirect ingress traffic from WAN to IFB
          ${pkgs.iproute2}/bin/tc qdisc add dev ${cfg.wanInterface} handle ffff: ingress 2>/dev/null || true
          ${pkgs.iproute2}/bin/tc filter add dev ${cfg.wanInterface} parent ffff: \
            protocol all u32 match u32 0 0 \
            action mirred egress redirect dev ifb4${cfg.wanInterface}

          # Apply CAKE to IFB egress (which handles WAN ingress/download)
          ${pkgs.iproute2}/bin/tc qdisc del dev ifb4${cfg.wanInterface} root 2>/dev/null || true
          ${pkgs.iproute2}/bin/tc qdisc add dev ifb4${cfg.wanInterface} root cake \
            bandwidth ${toString cfg.cake.downloadRate}kbit \
            ${lib.concatStringsSep " " (lib.filter (opt: opt != "ack-filter") cfg.cake.extraOptions)} \
            ethernet \
            overhead ${toString cfg.cake.overhead}

          echo "CAKE ingress (download) applied to ${cfg.wanInterface} via ifb4${cfg.wanInterface}: ${toString cfg.cake.downloadRate} kbit"
        '';

        preStop = ''
          # Clean up ingress shaping
          ${pkgs.iproute2}/bin/tc qdisc del dev ${cfg.wanInterface} ingress 2>/dev/null || true
          ${pkgs.iproute2}/bin/tc qdisc del dev ifb4${cfg.wanInterface} root 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip link set ifb4${cfg.wanInterface} down 2>/dev/null || true
          ${pkgs.iproute2}/bin/ip link del ifb4${cfg.wanInterface} 2>/dev/null || true
          echo "CAKE ingress removed from ${cfg.wanInterface}"
        '';
      };
    };
  };
}
