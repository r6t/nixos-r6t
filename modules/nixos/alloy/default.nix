{ lib, config, ... }:

let
  cfg = config.mine.alloy;
  alloyConfig = builtins.replaceStrings
    [ "@@LOKI_URL@@" "@@LOKI_TLS_INSECURE@@" ]
    [ cfg.lokiUrl (lib.boolToString cfg.lokiInsecureTls) ]
    (builtins.readFile ./config.alloy);
in
{
  options.mine.alloy = {
    enable = lib.mkEnableOption "enable alloy service";

    lokiUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://loki.r6t.io/loki/api/v1/push";
      description = "Loki push API URL. Override for hosts that reach Loki over LAN instead of tailnet.";
      example = "https://192.168.6.3/loki/api/v1/push";
    };

    lokiInsecureTls = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Skip TLS certificate verification for Loki. Use when pushing to an IP address where the cert won't match.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."alloy/config.alloy" = {
      text = alloyConfig;
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

