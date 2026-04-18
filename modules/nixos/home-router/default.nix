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

      staticLeases = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            MACAddress = lib.mkOption {
              type = lib.types.str;
              description = "MAC address of the device";
            };
            Address = lib.mkOption {
              type = lib.types.str;
              description = "IP address to assign";
            };
          };
        });
        default = [ ];
        example = [
          { MACAddress = "aa:bb:cc:dd:ee:ff"; Address = "192.168.6.9"; }
        ];
        description = "Static DHCP leases (MAC to IP reservations)";
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

    # Health check configuration
    healthCheck = {
      enable = lib.mkEnableOption "periodic router health checks logged to journald";

      interval = lib.mkOption {
        type = lib.types.str;
        default = "20min";
        description = "How often to run the health check (systemd OnUnitActiveSec format)";
      };
    };

    # WAN watchdog - auto-recover from ISP drops where link stays up
    wanWatchdog = {
      enable = lib.mkEnableOption "WAN connectivity watchdog that bounces DHCP on failure";

      interval = lib.mkOption {
        type = lib.types.str;
        default = "2min";
        description = "How often to check WAN connectivity";
      };

      targets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ "1.1.1.1" "9.9.9.9" ];
        description = "IPs to ping — recovery triggers only if ALL are unreachable";
      };

      failuresBeforeRestart = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Consecutive failures before bouncing WAN DHCP";
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

  config = lib.mkIf cfg.enable (
    let
      routerArgs = "${cfg.wanInterface} ${cfg.lanInterface} ${cfg.lanAddress}";

      diagnosticsScript = pkgs.writeShellScriptBin "router-diagnostics" ''
        exec ${pkgs.fish}/bin/fish ${./router-diagnostics.fish} ${routerArgs}
      '';

      healthCheckScript = pkgs.writeShellScriptBin "router-health-check" ''
        exec ${pkgs.fish}/bin/fish ${./router-health-check.fish} ${routerArgs}
      '';

      wanWatchdogScript = pkgs.writeShellScriptBin "wan-watchdog" ''
        exec ${pkgs.fish}/bin/fish ${./wan-watchdog.fish} ${cfg.wanInterface} ${toString cfg.wanWatchdog.failuresBeforeRestart} ${lib.concatStringsSep " " cfg.wanWatchdog.targets}
      '';
    in
    {
      # Ensure iproute2 with CAKE support is available
      environment.systemPackages = [
        pkgs.iproute2
        pkgs.ethtool
        diagnosticsScript
      ];

      # Router kernel configuration
      boot = {
        kernel.sysctl = {
          # Router essentials
          "net.ipv4.conf.all.forwarding" = 1;
          # Disable IPv6 forwarding
          "net.ipv6.conf.all.forwarding" = 0;
          # Accept TCP packets that are "out of window" without marking INVALID.
          # Required for NAT environments where the AP may send TCP control frames
          # (RST/FIN) on behalf of idle clients, which corrupts conntrack state and
          # causes legitimate return traffic from cloud servers to be dropped.
          "net.netfilter.nf_conntrack_tcp_be_liberal" = 1;

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

                  # Invalid packets - log (rate-limited) and drop
                  ct state invalid limit rate 5/minute burst 5 packets log prefix "INVALID-PKT: "
                  ct state invalid drop

                  # Explicitly drop NEW connections from WAN (defense in depth)
                  iifname "${cfg.wanInterface}" ct state new limit rate 5/minute burst 5 packets log prefix "WAN-INPUT-DROP: "
                  iifname "${cfg.wanInterface}" ct state new drop

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
                  # Do not drop INVALID in the forward chain. Packets are marked INVALID
                  # when their conntrack entry has expired (e.g. cloud server sends a FIN
                  # or RST after conntrack tore down a half-closed TCP session for an IoT
                  # device). Dropping them here silently kills legitimate return traffic.
                  # The policy drop handles anything not explicitly accepted.
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
            no-hosts = true;
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

      # systemd configuration (networkd, services, timers)
      systemd = {
        network = {
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

            # Static DHCP leases (MAC -> IP reservations)
            dhcpServerStaticLeases = map
              (lease: {
                dhcpServerStaticLeaseConfig = {
                  inherit (lease) MACAddress Address;
                };
              })
              cfg.dhcpServer.staticLeases;
          };
        };

        # CAKE QoS services
        services = (lib.optionalAttrs cfg.cake.enable {
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
        }) // lib.optionalAttrs cfg.healthCheck.enable {
          router-health-check = {
            description = "Router health check";
            after = [ "network-online.target" "dnsmasq.service" ];
            wants = [ "network-online.target" ];
            path = [ pkgs.iproute2 pkgs.dig pkgs.nftables pkgs.iputils pkgs.systemd ];

            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${healthCheckScript}/bin/router-health-check";
            };
          };
        } // lib.optionalAttrs cfg.wanWatchdog.enable {
          wan-watchdog = {
            description = "WAN connectivity watchdog";
            after = [ "network-online.target" ];
            wants = [ "network-online.target" ];
            path = [ pkgs.iputils pkgs.systemd pkgs.coreutils ];

            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${wanWatchdogScript}/bin/wan-watchdog";
              RuntimeDirectory = "wan-watchdog";
            };
          };
        };

        timers = (lib.optionalAttrs cfg.healthCheck.enable {
          router-health-check = {
            description = "Periodic router health check";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "5min";
              OnUnitActiveSec = cfg.healthCheck.interval;
            };
          };
        }) // lib.optionalAttrs cfg.wanWatchdog.enable {
          wan-watchdog = {
            description = "Periodic WAN connectivity check";
            wantedBy = [ "timers.target" ];
            timerConfig = {
              OnBootSec = "3min";
              OnUnitActiveSec = cfg.wanWatchdog.interval;
            };
          };
        };
      };
    }
  );
}
