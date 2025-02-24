{ lib, config, ... }:

let
  dashboardDir = ./dashboards; 
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
    services.grafana = {
      enable = true;
      settings.server = {
        http_addr = "0.0.0.0";
        domain = "localhost";
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

