{ lib, config, pkgs, ... }:

{
  options.mine.prometheus.enable = lib.mkEnableOption "enable prometheus metrics server";

  config = lib.mkIf config.mine.prometheus.enable {
    services.prometheus = {
      enable = true;
      port = 9001;
      retentionTime = "30d";
      remoteWrite = [{
        url = "http://localhost:9090/api/v1/write";
      }];
      scrapeConfigs = [
        {
          job_name = "r6-nix-systems";
          honor_labels = true;
          static_configs = [{
            targets = [ "exit-node:9000" "moon:9000" "mountainball:9000" "saguaro:9000" ];
          }];
        }
      ];
      ruleFiles = [
        (pkgs.writeText "alert.rules" ''
          groups:
          - name: node_alerts
            rules:
            - alert: HighMemoryUsage
              expr: (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100 < 10
              for: 5m
        '')
      ];
    };
  };
}
