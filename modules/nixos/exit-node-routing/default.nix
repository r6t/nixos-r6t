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

        interfaces.eth0.useDHCP = false;

        wg-quick.interfaces.wg0 = {
          configFile = cfg.wgConfigFile;
          autostart = true;
        };

        nftables.enable = false;

        firewall = {
          enable = true;
          checkReversePath = "loose";
          allowPing = true;
          # Default-deny forwarding keeps this acting only as an explicit
          # LAN/tailnet -> Mullvad router, with a kill-switch if wg0 is down.
          extraCommands = ''
            iptables -D FORWARD -o eth0 ! -d 192.168.6.0/24 -m comment --comment exit-node-killswitch -j DROP 2>/dev/null || true
            iptables -D FORWARD -m comment --comment exit-node-default-deny -j DROP 2>/dev/null || true
            iptables -I FORWARD -o eth0 ! -d 192.168.6.0/24 -m comment --comment exit-node-killswitch -j DROP
            iptables -A FORWARD -m comment --comment exit-node-default-deny -j DROP
          '';
          extraStopCommands = ''
            iptables -D FORWARD -o eth0 ! -d 192.168.6.0/24 -m comment --comment exit-node-killswitch -j DROP 2>/dev/null || true
            iptables -D FORWARD -m comment --comment exit-node-default-deny -j DROP 2>/dev/null || true
          '';
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
      mine.tailscale = {
        enable = true;
        ephemeral = true;
        extraUpFlags = [
          "--advertise-exit-node"
        ];
      };

      services.tailscale = {
        useRoutingFeatures = lib.mkForce "server";
      };

      networking.nat.internalInterfaces = [ "tailscale0" ];

      systemd.services = {
        tailscale-tailnet-routes = {
          description = "Keep tailnet routes on tailscale0";
          after = [ "tailscaled.service" ];
          wants = [ "tailscaled.service" ];
          wantedBy = [ "multi-user.target" ];
          path = [ pkgs.iproute2 pkgs.coreutils ];
          script = ''
            for _ in $(seq 1 30); do
              if ip link show tailscale0 >/dev/null 2>&1; then
                ip route replace 100.64.0.0/10 dev tailscale0
                ip -6 route replace fd7a:115c:a1e0::/48 dev tailscale0
                exit 0
              fi
              sleep 1
            done

            echo "tailscale0 not present; skipping tailnet route pinning"
          '';
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
        };

        # GRO forwarding for exit node
        # https://tailscale.com/kb/1320/performance-best-practices#ethtool-configuration
        tailscale-network-optimizations = {
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
        tailscaled = {
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
    })
  ]);
}
