{ lib, config,  ... }:

{
  options.mine.prometheus.enable = lib.mkEnableOption "enable prometheus metrics server";

  config = lib.mkIf config.mine.prometheus.enable {
    services.prometheus = {
      enable = true;
      port = 9001;
      retentionTime = "30d";
      exporters.node = {
        enable = true;
        enabledCollectors = ["systemd"];
        port = 9100;
      };
    };
  };
}

