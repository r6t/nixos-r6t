{ lib, cfg }:

{
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

        # Logging
        log-queries = true;

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

  systemd.network = {
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
          inherit (lease) MACAddress Address;
        })
        cfg.dhcpServer.staticLeases;
    };
  };
}
