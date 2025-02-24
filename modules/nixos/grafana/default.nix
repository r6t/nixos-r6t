{ lib, config, ... }:

{
  options.mine.grafana.enable = lib.mkEnableOption "enable grafana service";

  config = lib.mkIf config.mine.grafana.enable {
    services.grafana = {
      enable = true;
      settings.server = {
        http_addr = "0.0.0.0";
        domain = "localhost";
      };
      provision.datasources.settings.datasources = [
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
    };
  };
}

