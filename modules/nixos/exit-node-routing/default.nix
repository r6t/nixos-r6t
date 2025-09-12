{ lib, config, pkgs, ... }: {

  # requires eth0, tailscale0, DNS running on 127.0.0.1
  options = {
    mine.exit-node-routing.enable =
      lib.mkEnableOption "set systemwide wireguard tunnel, enable tailscale exit node routing thru it";

    mine.exit-node-routing.wgConfigFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/wireguard/wg0.conf";
      description = "WireGuard configuration file path";
    };
  };

  config = lib.mkIf config.mine.exit-node-routing.enable {

    boot = {
      kernel.sysctl = {
        "net.ipv4.ip_forward" = true;
        "net.ipv6.conf.all.forwarding" = true;

        # New 2509
        # Modern conntrack limits for high-throughput exit nodes
        "net.netfilter.nf_conntrack_max" = 2097152;
        "net.netfilter.nf_conntrack_buckets" = 524288;

        # High-throughput buffering
        "net.core.rmem_max" = 134217728;
        "net.core.wmem_max" = 134217728;
        "net.ipv4.tcp_rmem" = "4096 87380 134217728";
        "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      };
    };

    environment.systemPackages = with pkgs; [ iperf nettools ];

    # Static networking to keep things managed
    networking = {
      defaultGateway = {
        address = "192.168.6.1";
        interface = "eth0";
      };
      nameservers = [ "127.0.0.1" ];
      # Static interface configuration
      interfaces = {
        eth0 = {
          useDHCP = false;
          ipv4 = {
            # let cloud-init set IP
            routes = [
              {
                address = "192.168.6.0";
                prefixLength = 24;
                via = "192.168.6.1";
              }
            ];
          };
        };
        # Static routes to keep tailnet traffic on tailscale interface
        tailscale0 = {
          ipv4.routes = [
            {
              address = "100.64.0.0";
              prefixLength = 10;
            }
          ];
          ipv6.routes = [
            {
              address = "fd7a:115c:a1e0::";
              prefixLength = 48;
            }
          ];
        };
      };

      # Wireguard connection to privacy VPN service
      wg-quick.interfaces = {
        wg0 = {
          configFile = config.mine.exit-node-routing.wgConfigFile;
          autostart = true;
        };
      };

      nftables.enable = false;

      firewall = {
        enable = true;
        checkReversePath = "loose";
        trustedInterfaces = [ "tailscale0" ];
        allowPing = true;
      };

      nat = {
        enable = true;
        externalInterface = "wg0";
        internalInterfaces = [ "tailscale0" "eth0" ];
      };
    };

    # Enable Tailscale with exit node option
    services.tailscale = {
      enable = true;
      useRoutingFeatures = lib.mkForce "server";
    };

    # GRO forwarding for exit node
    # https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration
    systemd.services.tailscale-network-optimizations = {
      description = "Apply network optimizations for Tailscale";
      after = [ "network.target" "tailscale.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.iproute2 pkgs.ethtool ];
      script = ''
        ethtool -K eth0 rx-udp-gro-forwarding on rx-gro-list off || true
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # Wait for network stability
    # use iptables - nftables seems to have stability issues in LXC
    systemd.services.tailscaled = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      environment = {
        TS_DEBUG_FIREWALL_MODE = "iptables";
      };
      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      };
    };
  };
}

