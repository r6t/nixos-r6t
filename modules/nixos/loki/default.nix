{ lib, config, pkgs, ... }: {

  options.mine.loki.enable = lib.mkEnableOption "Loki log aggregation";

  config = lib.mkIf config.mine.loki.enable {

    services.loki = {
      enable = true;
      configuration =
        let
          retentionDays = 7;
        in
        {
          auth_enabled = false;
          server = {
            http_listen_port = 3030;
            http_listen_address = "0.0.0.0";
          };

          common = {
            path_prefix = "/var/lib/loki";
            storage = {
              filesystem = {
                chunks_directory = "/var/lib/loki/chunks";
                rules_directory = "/var/lib/loki/rules";
              };
            };
            replication_factor = 1;
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
            filesystem = {
              directory = "/var/lib/loki/chunks";
            };
            tsdb_shipper = {
              active_index_directory = "/var/lib/loki/tsdb-active";
              cache_location = "/var/lib/loki/tsdb-cache";
              cache_ttl = "${toString (retentionDays * 24)}h";
            };
          };

          ingester = {
            lifecycler = {
              ring = {
                kvstore.store = "memberlist";
                replication_factor = 1;
              };
            };
            chunk_idle_period = "30m";
            chunk_target_size = 1572864;
          };

          limits_config = {
            reject_old_samples = true;
            reject_old_samples_max_age = "${toString (retentionDays * 24)}h";
            retention_period = "${toString (retentionDays * 24)}h";
          };

          compactor = {
            working_directory = "/var/lib/loki/compactor";
            compaction_interval = "15m";
	    #            retention_enabled = true;
	    #            retention_delete_delay = "2h";
	    # delete_request_store = "filesystem";
            # delete_request_store_config = {
            #   directory = "/var/lib/loki/delete_requests";
            # };
          };
        };
    };

    systemd.tmpfiles.rules = [
      "d /var/lib/loki 0755 loki loki - -"
      "d /var/lib/loki/tsdb-active 0755 loki loki - -"
      "d /var/lib/loki/tsdb-cache 0755 loki loki - -"
      "d /var/lib/loki/compactor 0755 loki loki - -"
      "d /var/lib/loki/chunks 0755 loki loki - -"
      "d /var/lib/loki/rules 0755 loki loki - -"
      "d /var/lib/loki/delete_requests 0755 loki loki - -"
    ];

    environment.systemPackages = [ pkgs.loki ];
  };
}

