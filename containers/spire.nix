{ lib, ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/monitoring-services/default.nix
    ../modules/nixos/prometheus-node-exporter/default.nix
    ../modules/nixos/tailscale/default.nix
  ];

  networking.hostName = "spire";

  # Match existing data ownership (r6t:users = 1000:100)
  users.users.pocket-id = {
    uid = lib.mkForce 1000;
    group = "users";
    isSystemUser = true;
    home = "/var/lib/pocket-id";
  };

  services = {
    # Don't let tailscale overwrite resolv.conf — dnsmasq is the authoritative
    # resolver in this container and must serve *.r6t.io overrides.
    # MagicDNS hostnames (crown, mountainball) are forwarded via dnsmasq below.
    tailscale.extraUpFlags = [ "--accept-dns=false" "--ephemeral" ];

    # Forward tailnet MagicDNS queries to Tailscale's resolver so Prometheus
    # can scrape bare hostnames (crown, mountainball) via the tailnet.
    dnsmasq.settings.server = [ "/cloudforest-darter.ts.net/100.100.100.100" ];

    pocket-id = {
      enable = true;
      user = "pocket-id";
      group = "users";

      # Data directory mounted by Incus from persistent storage
      dataDir = "/var/lib/pocket-id";

      # ENCRYPTION_KEY and other secrets in this file on persistent storage
      environmentFile = "/var/lib/pocket-id/pocket-id.env";

      settings = {
        APP_URL = "https://pid.r6t.io";
        TRUST_PROXY = true;
      };
    };
  };

  # After tailscale deregisters its resolvconf interface (--accept-dns=false),
  # regenerate resolv.conf so dnsmasq on 127.0.0.1 is restored as the resolver.
  systemd.services.restore-resolv = {
    description = "Restore resolv.conf to dnsmasq after tailscale deregisters DNS";
    after = [ "tailscaled-autoconnect.service" "cloud-init.service" ];
    wants = [ "tailscaled-autoconnect.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/run/current-system/sw/bin/resolvconf -u";
      RemainAfterExit = true;
    };
  };

  mine = {
    tailscale.enable = true;
    tailscale.authKeyFile = "/etc/tailscale/auth-key";
    monitoring-services = {
      enable = true;
      grafana.domain = "grafana.r6t.io";
      grafana.oidc = {
        signoutRedirectUrl = "https://pid.r6t.io/";
        authUrl = "https://pid.r6t.io/authorize";
        tokenUrl = "https://pid.r6t.io/api/oidc/token";
        apiUrl = "https://pid.r6t.io/api/oidc/userinfo";
      };
      prometheus.scrapeTargets = [ "crown:9000" "mountainball:9000" "192.168.6.1:9000" ];
      prometheus.incusMetricsTargets = [ "crown:9101" "192.168.6.1:9101" ];
    };
    prometheus-node-exporter.enable = true;
  };
}
