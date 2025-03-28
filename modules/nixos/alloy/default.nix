{ lib, config, ... }:

let
  cfg = config.mine.alloy;
  alloy_base_conf = ./config.alloy;
in
{
  options.mine.alloy = {
    enable = lib.mkEnableOption "enable alloy service";
  };

  config = lib.mkIf cfg.enable {
    environment.etc."alloy/config.alloy" = {
      text = builtins.readFile alloy_base_conf;
    };

    services.alloy = {
      enable = true;
      extraFlags = [
        "--server.http.listen-addr=0.0.0.0:12346"
        "--disable-reporting"
      ];
    };

    systemd.services.alloy = {
      serviceConfig = {
        User = "root";
        Group = "root";
        DynamicUser = lib.mkForce false;
      };
    };
  };
}

