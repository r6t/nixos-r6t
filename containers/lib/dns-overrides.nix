# DNS overrides for app containers on crown's LAN.
# Resolves *.r6t.io to crown's caddy (192.168.6.10) so containers
# can reach reverse-proxied services without leaving the LAN.
# Exit nodes override this to empty — tailnet clients using exit nodes
# must resolve via public DNS, not LAN IPs they can't route to.
{
  services.dnsmasq.settings.address = [
    # crown (192.168.6.10) — caddy reverse proxy for most services
    "/r6t.io/192.168.6.10"
  ];
}
