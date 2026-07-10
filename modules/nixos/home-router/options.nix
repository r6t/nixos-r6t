{ lib, config, ... }:

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

      sourceTcpPorts = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            source = lib.mkOption {
              type = lib.types.str;
              example = "192.168.6.3";
              description = "Literal LAN source IP or CIDR to allow. Do not use DNS names here.";
            };
            ports = lib.mkOption {
              type = lib.types.listOf lib.types.int;
              example = [ 9000 12346 ];
              description = "TCP ports to allow from this LAN source.";
            };
          };
        });
        default = [ ];
        example = [
          { source = "192.168.6.3"; ports = [ 9000 9101 12346 ]; }
        ];
        description = "Source-restricted TCP ports to allow from LAN only.";
      };
    };

    mssClamping = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable TCP MSS clamping to prevent PMTU discovery issues on WAN";
    };

    flowOffload = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable nftables flow offloading for established connections (reduces CPU usage)";
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
}
