{ lib, config, pkgs, ... }: {

  options.mine.loki.enable = lib.mkEnableOption "Loki + grafana-alloy log aggregation system";

  config = lib.mkIf config.mine.loki.enable {

    # Loki server configuration
    services.loki = {
      enable = true;
      configuration = let
        retentionDays = 7;
      in {
        server.http_listen_port = 3030;

        common = {
          storage = {
            filesystem = {
              chunks_directory = "/var/lib/loki/chunks";
              rules_directory = "/var/lib/loki/rules";
            };
          };
        };

        schema_config = {
          configs = [{
            from = "2025-02-18";
            store = "tsdb";
            object_store = "filesystem";
            schema = "v13";
            index = {
              prefix = "index_";
              period = "24h";
            };
          }];
        };

        storage_config = {
          tsdb_shipper = {
            active_index_directory = "/var/lib/loki/tsdb-active";
            cache_location = "/var/lib/loki/tsdb-cache";
            cache_ttl = "${toString (retentionDays * 24)}h";
          };
        };

        ingester = {
          lifecycler = {
            ring = {
              kvstore.store = "inmemory";
              replication_factor = 1;
            };
          };
          chunk_idle_period = "30m";
          chunk_target_size = 1572864;
        };

        limits_config = {
          reject_old_samples = true;
          reject_old_samples_max_age = "${toString (retentionDays * 24)}h";
        };

        compactor = {
          working_directory = "/var/lib/loki/compactor";
          compaction_interval = "15m";
          retention_enabled = true;
          retention_delete_delay = "2h";
          delete_request_store = "filesystem";
        };
      };
    };


    # Alloy 
    users.users.alloy = {
      isSystemUser = true;
      description = "Grafana Alloy Service User";
      group = "alloy";
      home = "/var/lib/alloy";
      createHome = true;
    };
    users.groups.alloy = {};

    environment.etc."alloy/config.river".text = let
      loki_port = toString config.services.loki.configuration.server.http_listen_port;
    in ''
      loki.source.file "system" {
        targets = [
          {
            __path__ = "/var/log/**/*.log",
            job = "varlogs",
          },
        ]
        forward_to = [loki.write.default.receiver]
      }
    
      loki.write "default" {
        endpoint {
          url = "http://localhost:${loki_port}/loki/api/v1/push"
        }
      }
    '';

    systemd.services.alloy = {
      enable = true;
      description = "Grafana Alloy - Unified Telemetry Collector";
    
      serviceConfig = {
	ExecStart = "${pkgs.grafana-alloy}/bin/alloy run /etc/alloy/config.river";
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
    };
    
    # Ensure necessary directories exist
    systemd.tmpfiles.rules = [
      "d /var/lib/loki 0755 loki loki - -"
      "d /var/lib/loki/tsdb-active 0755 loki loki - -"
      "d /var/lib/loki/tsdb-cache 0755 loki loki - -"
      "d /var/lib/loki/compactor 0755 loki loki - -"
      "d /var/lib/loki/chunks 0755 loki loki - -"
      "d /var/lib/loki/rules 0755 loki loki - -"
      "d /var/lib/alloy 0755 alloy alloy - -"
    ];

    # Add Loki to system packages for CLI use
    environment.systemPackages = [ pkgs.loki pkgs.grafana-alloy ];
  };
}

