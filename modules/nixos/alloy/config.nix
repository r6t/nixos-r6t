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
}
