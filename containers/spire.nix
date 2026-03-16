{ lib, pkgs, config, ... }:

let
  allCaddyRoutes = import ./lib/caddy-routes.nix;
  route53ZoneId = "Z01277829BV9937NUSIW";
  route53Record = "spire.r6t.io";
in
{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/caddy/default.nix
    ../modules/nixos/iperf/default.nix
    ../modules/nixos/monitoring-services/default.nix
    ../modules/nixos/prometheus-node-exporter/default.nix
    ../modules/nixos/tailscale/default.nix
  ];

  networking = {
    hostName = "spire";
    # Open 443 on LAN so saguaro's Alloy can reach caddy for Loki push.
    # Tailnet access is already covered by tailscale0 trusted interface.
    firewall.allowedTCPPorts = [ 443 ];
  };

  # Match existing data ownership (r6t:users = 1000:100)
  users.users.pocket-id = {
    uid = lib.mkForce 1000;
    group = "users";
    isSystemUser = true;
    home = "/var/lib/pocket-id";
  };

  services.pocket-id = {
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

  mine = {
    caddy = {
      enable = true;
      environmentFile = "/etc/caddy/caddy.env";
      routes = allCaddyRoutes.spire;
    };
    iperf.enable = true;
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
    tailscale = {
      enable = true;
      # Auth key file bind-mounted by incus profile from host storage.
      # Use an ephemeral + reusable key so spire auto-joins the tailnet
      # on launch and auto-expires when deleted.
      authKeyFile = "/etc/tailscale/auth-key";
    };
  };

  # Update Route53 A record for spire.r6t.io after tailscale connects.
  # Ephemeral nodes get new IPs on each join, so this keeps DNS in sync.
  systemd.services.route53-update = {
    description = "Update Route53 A record with current Tailscale IP";
    after = [ "tailscaled-autoconnect.service" ];
    wants = [ "tailscaled-autoconnect.service" ];
    wantedBy = [ "multi-user.target" ];
    path = [ config.services.tailscale.package pkgs.awscli2 pkgs.jq ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      EnvironmentFile = "/etc/caddy/caddy.env";
    };
    script = ''
      # Wait for tailscale to be fully connected
      for i in $(seq 1 30); do
        TS_IP=$(tailscale ip -4 2>/dev/null)
        if [ -n "$TS_IP" ]; then
          break
        fi
        sleep 2
      done

      if [ -z "$TS_IP" ]; then
        echo "ERROR: Could not get Tailscale IPv4 address after 60s"
        exit 1
      fi

      echo "Tailscale IP: $TS_IP"

      # Check current DNS value
      CURRENT=$(aws route53 list-resource-record-sets \
        --hosted-zone-id "${route53ZoneId}" \
        --query "ResourceRecordSets[?Name=='${route53Record}.'].ResourceRecords[0].Value" \
        --output text 2>/dev/null)

      if [ "$CURRENT" = "$TS_IP" ]; then
        echo "Route53 already points to $TS_IP, no update needed"
        exit 0
      fi

      echo "Updating ${route53Record} from $CURRENT to $TS_IP"
      aws route53 change-resource-record-sets \
        --hosted-zone-id "${route53ZoneId}" \
        --change-batch "$(jq -n \
          --arg name "${route53Record}" \
          --arg ip "$TS_IP" \
          '{
            Changes: [{
              Action: "UPSERT",
              ResourceRecordSet: {
                Name: $name,
                Type: "A",
                TTL: 300,
                ResourceRecords: [{ Value: $ip }]
              }
            }]
          }'
        )"

      echo "Route53 updated successfully"
    '';
  };
}
