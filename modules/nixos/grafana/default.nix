{ lib, config, ... }:

let
  dashboardDir = ./dashboards;
  grafanaIni = ./grafana.ini;
in
{
  options.mine.grafana = {
    enable = lib.mkEnableOption "enable grafana service";
    dashboardDir = lib.mkOption {
      type = lib.types.path;
      default = dashboardDir;
      description = "path to grafana dashboards";
    };
  };

  config = lib.mkIf config.mine.grafana.enable {
    #    environment.etc."grafana/grafana.ini".source = grafanaIni;
    services.grafana = {
      enable = true;
      settings = {
        #        auth = {
        #          oauth_auto_login = true;
        #          signout_redirect_url = "https://pid.r6t.io/";
        #        };
        #
        #        "auth.basic" = {
        #          enabled = false;
        #        };
        #        "auth.generic_oauth" = {
        #          enabled = true;
        #          name = "Pocket-ID";
        #          allow_sign_up = true;
        #          scopes = "openid email profile";
        #          auth_url = "https://pid.r6t.io/authorize";
        #          token_url = "https://pid.r6t.io/api/oidc/token";
        #          api_url = "https://pid.r6t.io/api/oidc/userinfo";
        #          # Optional/advanced:
        #          # login_attribute_path = "email";
        #          # role_attribute_path = "contains(groups[*], 'admin') && 'Admin' || 'Viewer'";
        #          # allow_assign_grafana_admin = false;
        #        };

        server = {
          http_addr = "0.0.0.0";
          http_port = 3099;
          domain = "localhost";
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

