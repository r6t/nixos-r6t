{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "ntfy";

  services = {
    # DNS overrides for local resolution
    dnsmasq.settings.address = [
      "/grafana.r6t.io/192.168.6.1"
      "/r6t.io/192.168.6.10"
    ];

    ntfy-sh = {
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

    # MollySocket - Signal notifications via UnifiedPush
    # Connects to Signal servers and pushes notifications through ntfy
    mollysocket = {
      enable = true;

      settings = {
        # Listen on all interfaces for Caddy reverse proxy
        host = "0.0.0.0";
        port = 8020;

        # Allow local ntfy instance as push endpoint
        allowed_endpoints = [ "https://ntfy.r6t.io" ];

        # Allow all accounts (single user setup)
        allowed_uuids = [ "*" ];

        # VAPID key file in persistent storage
        # Generate: mollysocket vapid gen > /var/lib/mollysocket/vapid.key
        # Persisted via Incus mount to /var/lib/private/mollysocket
        vapid_key_file = "/var/lib/mollysocket/vapid.key";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 8083 8020 ];
}
