{ ... }:

{
  imports = [
    ./lib/base.nix
    ../modules/nixos/monitoring-services/options.nix
    ../modules/nixos/monitoring-services/config.nix
    ../modules/nixos/pocket-id/options.nix
    ../modules/nixos/pocket-id/config.nix
    ../modules/nixos/prometheus-node-exporter/default.nix
    ../modules/nixos/tailscale/default.nix
  ];

  networking.hostName = "spire";
  services.dnsmasq.settings.server = [ "192.168.6.1" ];

  mine = {
    pocket-id = {
      appUrl = "https://pid.r6t.io";
      dataDir = "/var/lib/pocket-id";
      environmentFile = "/var/lib/pocket-id/pocket-id.env";
    };
    tailscale = {
      enable = true;
      ephemeral = true;
      authKeyFile = "/etc/tailscale/auth-key";
    };
    monitoring-services = {
      grafana.domain = "grafana.r6t.io";
      grafana.oidc = {
        signoutRedirectUrl = "https://pid.r6t.io/";
        authUrl = "https://pid.r6t.io/authorize";
        tokenUrl = "http://localhost:1411/api/oidc/token";
        apiUrl = "http://localhost:1411/api/oidc/userinfo";
      };
      prometheus = {
        scrapeTargets = [ "crown:9000" "mountainball:9000" "192.168.6.1:9000" ];
        containerScrapeTargets = [ "spire:9000" ];
        incusMetricsTargets = [ "crown:9101" "192.168.6.1:9101" ];
      };
    };
    prometheus-node-exporter.enable = true;
  };
}
