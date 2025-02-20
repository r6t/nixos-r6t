{ lib, config, pkgs, ... }: {

  options.mine.alloy.enable = lib.mkEnableOption "grafana-alloy opentelemetry agent";

  config = lib.mkIf config.mine.alloy.enable {

    users.users.alloy = {
      isSystemUser = true;
      description = "Grafana Alloy Service User";
      group = "alloy";
      home = "/var/lib/alloy";
      createHome = true;
    };
    users.groups.alloy = { };

    environment.etc."alloy/config.river".text =
      let
        hostname = config.networking.hostName;
        excludedHosts = [ "homeassistant" "scottsdale" "truenas" ];
      in
      ''
        discovery.tailscale "peers" {
          filter = "os == \"linux\""
        } 

        prometheus.scrape "tailnet" {
          targets = [
            for host in discovery.tailscale.peers.targets : {
              // Explicit Tailscale IP access
              __address__ = "$${host.addresses[0]}:9100",
              __meta_tailscale_hostname = "$${host.name}",
              __meta_os = "$${host.os}"
            } if !std.member(${builtins.toJSON excludedHosts}, host.name)
          ]
          forward_to = [prometheus.remote_write.central.receiver]
        }

        prometheus.exporter.unix "system" {
          include_exporter_metrics = true
          disable_collectors = ["mdadm","zfs"]
        }

        prometheus.scrape "local_metrics" {
          targets    = prometheus.exporter.unix.system.targets
          forward_to = [prometheus.remote_write.central.receiver]
        }

        prometheus.remote_write "central" {
          endpoint {
            url = "http://moon:9001/api/v1/write"
          }
        }

        loki.source.file "system" {
          targets = [
            {
              __path__ = "/var/log/**/*.log",
              job = "varlogs",
            },
          ]
          forward_to = [loki.write.default.receiver]
        }

        loki.source.journal "systemd" {
          forward_to = [loki.write.default.receiver]
          labels = {job="systemd-journal", host="${hostname}"}
        }

        loki.source.file "auth" {
          targets = [{__path__ = "/var/log/auth.log"}]
          forward_to = [loki.write.default.receiver]
          labels = {job="auth", host="${hostname}"}
        }
    
        loki.write "default" {
          endpoint {
            url = "http://moon:3030/loki/api/v1/push"
          }
        }
      '';

    systemd.services.alloy = {
      enable = true;
      description = "Grafana Alloy - Unified Telemetry Collector";

      serviceConfig = {
        ExecStart = "${pkgs.grafana-alloy}/bin/alloy run /etc/alloy/config.river";
        RestartSec = "10s";
        RuntimeMaxSec = "300s";
        WorkingDirectory = "/var/lib/alloy";
        Restart = "always";
        User = "alloy";
        Group = "alloy";
        ReadWritePaths = [
          "/var/log"
          "/var/lib/alloy"
        ];
      };

      wantedBy = [ "multi-user.target" ];
      after = [ "tailscaled.service" ];
      requires = [ "tailscaled.service" ];
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/alloy 0755 alloy alloy - -"
    ];

    environment.systemPackages = [ pkgs.grafana-alloy ];
  };
}

