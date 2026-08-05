{ lib, ... }:

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

    lanCidr = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.0/24";
      description = "LAN CIDR allowed to route through the exit node.";
    };

    lanInterface = lib.mkOption {
      type = lib.types.str;
      default = "eth0";
      description = "LAN-facing interface.";
    };

    wgInterface = lib.mkOption {
      type = lib.types.str;
      default = "wg0";
      description = "WireGuard interface used for upstream egress.";
    };

    defaultGatewayAddress = lib.mkOption {
      type = lib.types.str;
      default = "192.168.1.1";
      description = "Default gateway address on the LAN.";
    };

    tailscaleInterface = lib.mkOption {
      type = lib.types.str;
      default = "tailscale0";
      description = "Tailscale interface name.";
    };

    tailnetIpv4Cidr = lib.mkOption {
      type = lib.types.str;
      default = "100.64.0.0/10";
      description = "Tailscale IPv4 CGNAT route to pin on the Tailscale interface.";
    };

    tailnetIpv6Cidr = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional Tailscale IPv6 route to pin on the Tailscale interface.";
    };
  };
}
