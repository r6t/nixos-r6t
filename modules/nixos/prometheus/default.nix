{ lib, config, pkgs, ... }: {

  options = {
    mine.prometheus.enable =
      lib.mkEnableOption "enable prometheus";
  };

  config = lib.mkIf config.mine.prometheus.enable {

    services.prometheus = {
      enable = true;
      port = 9001;
      exporters = {
        node = {
          enable = true;
          enabledCollectors = [ "systemd" ];
          port = 9002; # stringified and referenced in target config
        };
      };
      scrapeConfigs = [
        {
          job_name = "moon";
          static_configs = [{
            targets = [ "moon:${toString config.services.prometheus.exporters.node.port}" ];
          }];
        }
      ];
    };

    environment.systemPackages = with pkgs; [ prometheus ];
  };
}
