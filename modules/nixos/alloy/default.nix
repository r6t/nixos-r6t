{ lib, config, pkgs, ... }:

let
  allowedHosts = ["exit-node" "moon" "mountainball" "saguaro"];
  hostname = config.networking.hostName;
in {
  options.mine.alloy.enable = lib.mkEnableOption "Grafana Alloy agent";

  config = lib.mkIf config.mine.alloy.enable {
    environment.etc."alloy/config.river".text = ''
      loki.source.file "system" {
        targets = [{
          __path__ = "/var/log/**/*.log",
          job      = "varlogs",
          host     = "${hostname}",
        }]
        forward_to = [loki.write.default.receiver]
      }

      loki.source.journal "systemd" {
        forward_to = [loki.write.default.receiver]
        labels = {job="systemd-journal", host="${hostname}"}
      }

      loki.write "default" {
        endpoint {
          url = "http://moon:3030/loki/api/v1/push"
          headers = {
            "X-Scope-OrgID" = "fake"
          }
        }
      }

      prometheus.scrape "nixos_nodes" {
        targets = [
          ${lib.concatMapStringsSep "\n" (host: ''{__address__ = "${host}:9100", host = "${host}"},'') allowedHosts}
        ]
        forward_to = [prometheus.remote_write.central.receiver]
      }

      prometheus.remote_write "central" {
        endpoint {
          url = "http://moon:9001/api/v1/write"
        }
      }
    '';

    systemd.services.alloy = {
      serviceConfig = {
        ExecStart = "${pkgs.grafana-alloy}/bin/alloy run --debug /etc/alloy/config.river";
        Restart = "on-failure";
        RestartSec = "10s";
      };
    };
  };
}
