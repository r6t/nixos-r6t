# LAN DNS overrides for containers not on the tailnet.
# Resolves *.r6t.io services to the correct LAN host
# so containers can reach caddy reverse proxies directly.
{
  services.dnsmasq.settings.address = [
    # spire (192.168.6.3) — monitoring + auth on saguaro
    "/grafana.r6t.io/192.168.6.3"
    "/loki.r6t.io/192.168.6.3"
    "/pid.r6t.io/192.168.6.3"

    # crown (192.168.6.10) — everything else
    "/r6t.io/192.168.6.10"
  ];
}
