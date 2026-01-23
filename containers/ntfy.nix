{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "ntfy";

  # DNS overrides for local resolution
  services.dnsmasq.settings.address = [
    "/grafana.r6t.io/192.168.6.1"
    "/r6t.io/192.168.6.10"
  ];

  services.ntfy-sh = {
    enable = true;

    settings = {
      # External URL - accessed via Tailscale through Caddy
      base-url = "https://ntfy.r6t.io";

      # Listen on all interfaces for Caddy reverse proxy
      listen-http = "0.0.0.0:8083";

      # Behind Caddy reverse proxy on crown
      behind-proxy = true;

      # Message cache - persist messages for offline devices
      cache-file = "/var/lib/ntfy-sh/cache.db";
      cache-duration = "24h";

      # Attachments
      attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
      attachment-total-size-limit = "1G";
      attachment-file-size-limit = "15M";
      attachment-expiry-duration = "24h";

      # Keepalive for long-lived connections
      keepalive-interval = "45s";
    };
  };

  # Ensure attachment directory exists
  systemd.tmpfiles.rules = [
    "d /var/lib/ntfy-sh/attachments 0750 ntfy-sh ntfy-sh -"
  ];

  networking.firewall.allowedTCPPorts = [ 8083 ];
}
