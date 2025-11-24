{ lib, config, pkgs, ... }:

let
  cfg = config.mine.monitoring-services;
  alloyConfigFile = ./alloy/config.alloy;
  grafanaDashboardsDir = ./grafana/dashboards;
in
{
  options.mine.monitoring-services = {
    enable = lib.mkEnableOption "enable monitoring stack (alloy, grafana, loki, prometheus)";

    dataDir = lib.mkOption {
      type = lib.types.path;
      default = "/var/lib/monitoring";
      description = "Root directory for all monitoring service data storage";
      example = "/mnt/kingston240";
    };

    # Grafana options
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

    # Alloy options
    alloy = {
      httpListenAddr = lib.mkOption {
        type = lib.types.str;
        default = "0.0.0.0:12346";
        description = "HTTP listen address for Alloy";
      };
    };

    # Loki options
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

    # Prometheus options
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
        description = "List of scrape targets (host:port format)";
        example = [ "crown:9000" "mountainball:9000" "saguaro:9000" ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Alloy configuration
    environment = {
      etc."alloy/config.alloy" = {
        text = builtins.readFile alloyConfigFile;
      };
      systemPackages = [ pkgs.loki ];
    };

    services = {
      alloy = {
        enable = true;
        extraFlags = [
          "--server.http.listen-addr=${cfg.alloy.httpListenAddr}"
          "--disable-reporting"
        ];
      };

      grafana = {
        enable = true;
        dataDir = "${cfg.dataDir}/grafana";
        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = cfg.grafana.httpPort;
            inherit (cfg.grafana) domain;
            root_url = "https://${cfg.grafana.domain}";
            enforce_domain = true;
          };
          "auth.basic" = {
            enabled = false;
          };
          "auth.generic_oauth" = {
            enabled = true;
            name = "Pocket ID";
            allow_sign_up = true;
            auto_login = true;
            signout_redirect_url = cfg.grafana.oidc.signoutRedirectUrl;
            client_id = "$__file{${cfg.dataDir}/grafana/oidc_client_id}";
            client_secret = "$__file{${cfg.dataDir}/grafana/oidc_client_secret}";
            scopes = "openid profile email";
            auth_url = cfg.grafana.oidc.authUrl;
            token_url = cfg.grafana.oidc.tokenUrl;
            api_url = cfg.grafana.oidc.apiUrl;
            use_pkce = true;
            use_refresh_token = true;
            role_attribute_path = "contains(groups[*], 'admins') && 'GrafanaAdmin' || 'Viewer'";
            allow_assign_grafana_admin = true;
          };
        };
        provision = {
          datasources.settings.datasources = [
            {
              name = "Prometheus";
              type = "prometheus";
              url = "http://localhost:${toString cfg.prometheus.httpPort}";
              isDefault = true;
            }
            {
              name = "Loki";
              type = "loki";
              url = "http://localhost:${toString cfg.loki.httpListenPort}";
              jsonData.httpHeaderName1 = "X-Scope-OrgID";
              secureJsonData.httpHeaderValue1 = "fake";
            }
          ];

          dashboards.settings.providers = [{
            name = "r6 nix-managed Dashboards";
            options.path = "${grafanaDashboardsDir}";
            disableDeletion = true;
            updateIntervalSeconds = 30;
          }];
        };
      };

      loki = {
        enable = true;
        dataDir = "${cfg.dataDir}/loki";
        configuration = {
          auth_enabled = false;
          server = {
            http_listen_port = cfg.loki.httpListenPort;
            http_listen_address = "0.0.0.0";
          };

          common = {
            path_prefix = "${cfg.dataDir}/loki";
            storage = {
              filesystem = {
                chunks_directory = "${cfg.dataDir}/loki/chunks";
                rules_directory = "${cfg.dataDir}/loki/rules";
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
              directory = "${cfg.dataDir}/loki/chunks";
            };
            tsdb_shipper = {
              active_index_directory = "${cfg.dataDir}/loki/tsdb-active";
              cache_location = "${cfg.dataDir}/loki/tsdb-cache";
              cache_ttl = "${toString (cfg.loki.retentionDays * 24)}h";
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
            reject_old_samples_max_age = "${toString (cfg.loki.retentionDays * 24)}h";
            retention_period = "${toString (cfg.loki.retentionDays * 24)}h";
          };

          compactor = {
            working_directory = "${cfg.dataDir}/loki/compactor";
            compaction_interval = "15m";
          };
        };
      };

      prometheus = {
        enable = true;
        port = cfg.prometheus.httpPort;
        stateDir = "monitoring/prometheus";
        inherit (cfg.prometheus) retentionTime;
        remoteWrite = [{
          url = "http://localhost:9090/api/v1/write";
        }];
        scrapeConfigs = lib.optionals (cfg.prometheus.scrapeTargets != [ ]) [
          {
            job_name = "r6-nix-systems";
            honor_labels = true;
            static_configs = [{
              targets = cfg.prometheus.scrapeTargets;
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

    systemd = {
      services =
        let
          # Determine mount unit name from dataDir path
          mountUnit = lib.strings.removePrefix "/" (lib.strings.replaceStrings [ "/" ] [ "-" ] cfg.dataDir) + ".mount";
          # Check if dataDir is not in /var/lib (which would need a mount dependency)
          needsMountDependency = !(lib.hasPrefix "/var/lib" cfg.dataDir);
          mountDependency = lib.optionalAttrs needsMountDependency {
            after = [ mountUnit ];
            requires = [ mountUnit ];
          };
        in
        {
          alloy = mountDependency // {
            serviceConfig = {
              User = "root";
              Group = "root";
              DynamicUser = lib.mkForce false;
            };
          };

          grafana = mountDependency // {
            serviceConfig.StateDirectory = lib.mkForce "monitoring/grafana";
          };

          loki = mountDependency // {
            serviceConfig.StateDirectory = lib.mkForce "monitoring/loki";
          };

          prometheus = mountDependency // {
            serviceConfig.StateDirectory = lib.mkForce "monitoring/prometheus";
          };
        };

      tmpfiles.rules = [
        # Create symlink from /var/lib/monitoring to actual storage location
        "L+ /var/lib/monitoring - - - - ${cfg.dataDir}"

        # Loki directories (using actual dataDir path)
        "d ${cfg.dataDir}/loki 0755 loki loki - -"
        "d ${cfg.dataDir}/loki/tsdb-active 0755 loki loki - -"
        "d ${cfg.dataDir}/loki/tsdb-active/uploader 0755 loki loki - -"
        "d ${cfg.dataDir}/loki/tsdb-cache 0755 loki loki - -"
        "d ${cfg.dataDir}/loki/compactor 0755 loki loki - -"
        "d ${cfg.dataDir}/loki/chunks 0755 loki loki - -"
        "d ${cfg.dataDir}/loki/rules 0755 loki loki - -"
        "d ${cfg.dataDir}/loki/delete_requests 0755 loki loki - -"

        # Grafana and Prometheus directories
        "d ${cfg.dataDir}/grafana 0755 grafana grafana - -"
        "d ${cfg.dataDir}/prometheus 0755 prometheus prometheus - -"
      ];
    };
  };
}
