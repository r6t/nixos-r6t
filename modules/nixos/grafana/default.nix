{ lib, config, ... }: {

  options = {
    mine.grafana.enable =
      lib.mkEnableOption "enable grafana - module written with a single host in mind";
  };

  config = lib.mkIf config.mine.grafana.enable {

    services.grafana = {
      enable = true;
      settings = {
        server = {
          http_addr = "0.0.0.0";
          domain = "localhost";
          serve_from_sub_path = true;
        };
      };
      provision.datasources.settings.datasources = [
        {
          name = "Prometheus";
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:9001";
          isDefault = true;
        }
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://localhost:3030";
          jsonData = { };
          secureJsonData = { };
          editable = true;
          orgId = 1;
          version = 1;
          secureJsonFields = { };
          jsonData = {
            httpHeaderName1 = "X-Scope-OrgID";
          };
          secureJsonData = {
            httpHeaderValue1 = "fake";
          };
        }
      ];
    };
  };
}
