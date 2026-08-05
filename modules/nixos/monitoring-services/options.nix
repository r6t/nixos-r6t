{ lib, ... }:

{
  options.mine.monitoring-services = {
    enable = lib.mkEnableOption "enable monitoring stack (alloy, grafana, loki, prometheus)";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/monitoring";
      description = "Root directory for all monitoring service data storage";
      example = "/mnt/kingston240";
    };

    grafana = {
      httpPort = lib.mkOption {
        type = lib.types.port;
        default = 3099;
        description = "HTTP port for Grafana web interface";
      };

      domain = lib.mkOption {
        type = lib.types.str;
        description = "Domain name for Grafana";
        example = "grafana.example.com";
      };

      oidc = {
        signoutRedirectUrl = lib.mkOption {
          type = lib.types.str;
          description = "OIDC signout redirect URL";
          example = "https://pid.example.com/";
        };

        authUrl = lib.mkOption {
          type = lib.types.str;
          description = "OIDC authorization URL";
          example = "https://pid.example.com/authorize";
        };

        tokenUrl = lib.mkOption {
          type = lib.types.str;
          description = "OIDC token URL";
          example = "https://pid.example.com/api/oidc/token";
        };

        apiUrl = lib.mkOption {
          type = lib.types.str;
          description = "OIDC user info API URL";
          example = "https://pid.example.com/api/oidc/userinfo";
        };
      };
    };

    alloy = {
      httpListenAddr = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0:12346";
        description = "HTTP listen address for Alloy";
      };
    };

    loki = {
      httpListenPort = lib.mkOption {
        type = lib.types.port;
        default = 3030;
        description = "HTTP listen port for Loki";
      };

      retentionDays = lib.mkOption {
        type = lib.types.int;
        default = 30;
        description = "Log retention period in days";
      };
    };

    prometheus = {
      httpPort = lib.mkOption {
        type = lib.types.port;
        default = 9001;
        description = "HTTP port for Prometheus";
      };

      retentionTime = lib.mkOption {
        type = lib.types.str;
        default = "30d";
        description = "Metrics retention time";
      };

      scrapeTargets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of physical node-exporter scrape targets (host:port format)";
        example = [ "crown:9000" "mountainball:9000" "saguaro:9000" ];
      };

      containerScrapeTargets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of container node-exporter scrape targets (host:port format)";
        example = [ "localhost:9000" ];
      };

      incusMetricsTargets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "List of incus metrics endpoints (host:port format). Requires core.metrics_address and core.metrics_authentication=false set on the incus host.";
        example = [ "crown:9101" ];
      };
    };
  };
}
