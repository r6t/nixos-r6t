{ lib, config, pkgs, ... }:
let
  cfg = config.mine.exit-node-routing;
in
{
  options.mine.exit-node-routing = {
    enable = lib.mkEnableOption "systemwide wireguard tunnel for exit node routing";

    wgConfigFile = lib.mkOption {
      type = lib.types.path;
      default = "/etc/wireguard/wg0.conf";
      description = "WireGuard configuration file path";
    };

    enableTailscale = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Tailscale exit node routing through the WireGuard tunnel";
    };
  };

  config = lib.mkIf cfg.enable (lib.mkMerge [
    # Base WireGuard exit node configuration
    {
      boot.kernel.sysctl = {
        "net.ipv4.ip_forward" = true;
        "net.ipv6.conf.all.forwarding" = true;

        # Modern conntrack limits for high-throughput exit nodes
        "net.netfilter.nf_conntrack_max" = 2097152;
        "net.netfilter.nf_conntrack_buckets" = 524288;

        # High-throughput buffering
        "net.core.rmem_max" = 134217728;
        "net.core.wmem_max" = 134217728;
        "net.ipv4.tcp_rmem" = "4096 87380 134217728";
        "net.ipv4.tcp_wmem" = "4096 65536 134217728";
      };

      environment.systemPackages = with pkgs; [ iperf nettools ];

      networking = {
        defaultGateway = {
          address = "192.168.6.1";
          interface = "eth0";
        };
        nameservers = [ "127.0.0.1" ];

        interfaces.eth0 = {
          useDHCP = false;
          ipv4.routes = [
            {
              address = "192.168.6.0";
              prefixLength = 24;
              via = "192.168.6.1";
            }
          ];
        };

        wg-quick.interfaces.wg0 = {
          configFile = cfg.wgConfigFile;
          autostart = true;
        };

        nftables.enable = false;

        firewall = {
          enable = true;
          checkReversePath = "loose";
          allowPing = true;
        };

        nat = {
          enable = true;
          externalInterface = "wg0";
          internalInterfaces = [ "eth0" ];
        };
      };
    }

    # Tailscale-specific configuration
    (lib.mkIf cfg.enableTailscale {
      mine.tailscale.enable = true;

      services.tailscale.useRoutingFeatures = lib.mkForce "server";

      # Tailscale MagicDNS as secondary DNS for coordination server access
      services.dnsmasq.settings.server = [ "100.100.100.100" ];

      networking = {
        # Static routes to keep tailnet traffic on tailscale interface
        interfaces.tailscale0 = {
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

        nat.internalInterfaces = [ "tailscale0" ];
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
    })
  ]);
}
