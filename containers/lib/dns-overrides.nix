# DNS overrides for app containers on crown's LAN.
# Resolves *.r6t.io to crown's caddy (192.168.6.10) so containers
# can reach reverse-proxied services without leaving the LAN.
# Exit nodes and Tailscale-encrypted containers override this to false.
{ lib, config, ... }: {
  options.mine.dns-overrides.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = "Whether to use LAN-only DNS overrides for *.r6t.io";
  };

  config = lib.mkIf config.mine.dns-overrides.enable {
    services.dnsmasq.settings.address = [
      "/r6t.io/192.168.6.10"
    ];
  };
}
