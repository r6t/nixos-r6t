# Base DNS overrides for ALL containers (including exit nodes).
# Only includes the crown wildcard — safe for exit node clients
# who resolve spire services via public DNS / tailscale.
{
  services.dnsmasq.settings.address = [
    # crown (192.168.6.10) — caddy reverse proxy for most services
    "/r6t.io/192.168.6.10"
  ];
}
