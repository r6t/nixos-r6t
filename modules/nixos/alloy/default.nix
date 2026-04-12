{ lib, config, ... }:

let
  cfg = config.mine.alloy;
  syslogBlock = ''
    // Syslog from network devices (e.g. UniFi Alien WAP at 192.168.6.8)
    loki.source.syslog "network_devices" {
      listener {
        address  = "0.0.0.0:514"
        protocol = "udp"
      }
      forward_to = [loki.process.syslog_relabel.receiver]
    }

    loki.process "syslog_relabel" {
      forward_to = [loki.write.grafana_loki.receiver]

      stage.static_labels {
        values = {
          source = "syslog",
        }
      }
    }
  '';

  alloyConfig = builtins.replaceStrings
    [ "@@LOKI_URL@@" "@@LOKI_TLS_INSECURE@@" ]
    [ cfg.lokiUrl (lib.boolToString cfg.lokiInsecureTls) ]
    (builtins.readFile ./config.alloy)
  + (lib.optionalString cfg.syslogListen syslogBlock);
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

    syslogListen = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Listen for UDP syslog on port 514 and forward to Loki. Enable on the host closest to network devices sending syslog.";
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

