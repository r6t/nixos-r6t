{ lib, config, ... }:

let
  retentionDays = 7;
in {
  options.mine.loki.enable = lib.mkEnableOption "Loki log aggregation";

  config = lib.mkIf config.mine.loki.enable {
    services.loki = {
      enable = true;
      configuration = {
        auth_enabled = false;
        server.http_listen_port = 3030;
        common.storage.filesystem = {
          chunks_directory = "/var/lib/loki/chunks";
          rules_directory = "/var/lib/loki/rules";
        };
        schema_config.configs = [{
          from = "2025-02-18";
          store = "tsdb";
          object_store = "filesystem";
          schema = "v13";
        }];
        storage_config.tsdb_shipper = {
          active_index_directory = "/var/lib/loki/tsdb-active";
          cache_location = "/var/lib/loki/tsdb-cache";
          cache_ttl = "${toString (retentionDays * 24)}h";
        };
        limits_config.retention_period = "${toString (retentionDays * 24)}h";
      };
    };
  };
}

