{ lib, config, ... }:

let
  dashboardDir = ./dashboards;
in
{
  options.mine.grafana = {
    enable = lib.mkEnableOption "enable grafana service in monitoring lxc";
    dashboardDir = lib.mkOption {
      type = lib.types.path;
      default = dashboardDir;
      description = "path to grafana dashboards";
    };
  };

  config = lib.mkIf config.mine.grafana.enable {
    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          http_port = 3099;
          domain = "grafana.r6t.io";
          root_url = "https://grafana.r6t.io";
          enforce_domain = true;
        };
        "auth.basic" = {
          enabled = false;
        };
        "auth.generic_oauth" = {
          enabled = true;
          name = "Pocket ID";
          allow_sign_up = true;
          auto_login = true;
          signout_redirect_url = "https://pid.r6t.io/";
          client_id = "$__file{/var/lib/grafana/oidc_client_id}";
          client_secret = "$__file{/var/lib/grafana/oidc_client_secret}";
          scopes = "openid profile email";
          auth_url = "https://pid.r6t.io/authorize";
          token_url = "https://pid.r6t.io/api/oidc/token";
          api_url = "https://pid.r6t.io/api/oidc/userinfo";
          use_pkce = true;
          use_refresh_token = true;
          role_attribute_path = "contains(groups[*], 'admins') && 'GrafanaAdmin' || 'Viewer'";
          allow_assign_grafana_admin = true;
        };
      };
      provision = {
        datasources.settings.datasources = [
          {
            name = "Prometheus";
            type = "prometheus";
            url = "http://localhost:9001";
            isDefault = true;
          }
          {
            name = "Loki";
            type = "loki";
            url = "http://localhost:3030";
            jsonData.httpHeaderName1 = "X-Scope-OrgID";
            secureJsonData.httpHeaderValue1 = "fake";
          }
        ];

        dashboards.settings.providers = [{
          name = "r6 nix-managed Dashboards";
          options.path = "${config.mine.grafana.dashboardDir}";
          disableDeletion = true;
          updateIntervalSeconds = 30;
        }];
      };
    };
  };
}

