{ lib, config, pkgs, ... }: {

  options = {
    mine.grafana.enable =
      lib.mkEnableOption "enable grafana";
  };

  config = lib.mkIf config.mine.grafana.enable {

    services.grafana = {
      enable = true;
      settings = {
        server = {
          # Listening Address
          http_addr = "0.0.0.0";
          # and Port
          http_port = 3000;
          # Grafana needs to know on which domain and URL it's running
          domain = "moon.magic.internal";
          root_url = "http://moon.magic.internal:3000/"; # Not needed if it is `https://your.domain/`
          serve_from_sub_path = true;
        };
      };
    };

    environment.systemPackages = with pkgs; [ grafana ];
  };
}
