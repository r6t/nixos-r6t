{ lib, config, pkgs, ... }: {

  options = {
    mine.exit-node-routing.enable =
      lib.mkEnableOption "set systemwide wireguard tunnel, enable tailscale exit node routing thru it";
  };

  config = lib.mkIf config.mine.exit-node-routing.enable {

    boot = {
      kernel.sysctl = {
        "net.ipv4.ip_forward" = true;
        "net.ipv6.conf.all.forwarding" = true;
      };
    };

    environment.systemPackages = with pkgs; [ iperf nettools ];

    # Static networking to keep things managed
    networking = {
      defaultGateway = {
        address = "192.168.6.1";
        interface = "eth0";
      };
      defaultGateway6 = {
        address = "fe80::ae1f:6bff:fe65:6849";
        interface = "eth0";
      };
      # nameserver for initial connections, /etc/resolv.conf gets overridden by tailscale service
      nameservers = [ "192.168.6.1" ];
      # Static interface configuration
      interfaces = {
        eth0 = {
          useDHCP = false;
          ipv4 = {
            addresses = [{
              address = "192.168.6.14";
              prefixLength = 24;
            }];
            routes = [
              {
                address = "192.168.6.0";
                prefixLength = 24;
                via = "192.168.6.1";
              }
              {
                address = "52.39.83.153";
                prefixLength = 32;
                via = "192.168.6.1";
              }
            ];
          };
          ipv6 = {
            addresses = [{
              address = "2601:602:9300:2::1238";
              prefixLength = 128;
            }];
            routes = [
              {
                address = "2600:1f14:2f74:aa8c:14a0:1ba7:b9b9:5847";
                prefixLength = 128;
                via = "fe80::ae1f:6bff:fe65:6849";
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
          address = [ "10.69.81.138/32" "fc00:bbbb:bbbb:bb01::6:5189/128" ];
          listenPort = 51820;
          privateKeyFile = "/root/mullvad.key";
          peers = [
            {
              publicKey = "4ke8ZSsroiI6Sp23OBbMAU6yQmdF3xU2N8CyzQXE/Qw=";
              allowedIPs = [ "0.0.0.0/0" "::/0" ];
              endpoint = "138.199.43.65:51820";
              persistentKeepalive = 25;
            }
          ];
        };
      };

      # Firewall configuration using nftables
      nftables.enable = true;

      firewall = {
        enable = true;
        #  allowedTCPPorts = [ 22 ];
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
        NETDEV=$(ip -o route get 8.8.8.8 | cut -f 5 -d " ")
        ethtool -K $NETDEV rx-udp-gro-forwarding on rx-gro-list off
      '';
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
    };

    # Wait for network stability
    systemd.services.tailscaled = {
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
      };
    };
  };
}

