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
  };
}
