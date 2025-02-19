{ lib, config, pkgs, ... }: {

  options = {
    mine.prometheus.enable =
      lib.mkEnableOption "enable prometheus";
  };

  config = lib.mkIf config.mine.prometheus.enable {

    services.prometheus = {
      enable = true;
      port = 9001;
      retentionTime = "30d";
      remoteWrite = [{
        url = "http://localhost:9090/api/v1/write";
      }];
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002; # stringified and referenced in target config
        };
      };
      scrapeConfigs = [
        {
          job_name = "alloy_nodes";
          honor_labels = true;
          static_configs = [{
            targets = [ "localhost:12345" ];
          }];
        }
      ];
    };

    environment.systemPackages = with pkgs; [ prometheus ];
  };
}
