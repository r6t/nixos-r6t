{ lib, ... }:

{
  options.mine.caddy = {
    enable = lib.mkEnableOption "enable caddy webserver";

    routes = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          upstream = lib.mkOption {
            type = lib.types.str;
            description = "Upstream address (e.g. http://localhost:8080)";
          };
          compress = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = "Enable gzip/zstd compression";
          };
          extraConfig = lib.mkOption {
            type = lib.types.lines;
            default = "";
            description = "Additional Caddyfile directives for this route";
          };
        };
      });
      default = { };
      description = "Caddy reverse proxy routes (domain -> upstream)";
      example = {
        "app.r6t.io" = { upstream = "http://localhost:8080"; };
      };
    };

    globalConfig = lib.mkOption {
      type = lib.types.lines;
      default = ''
        email {env.ACME_EMAIL}
        acme_dns route53 {
          region {env.AWS_REGION}
          access_key_id {env.AWS_ACCESS_KEY_ID}
          secret_access_key {env.AWS_SECRET_ACCESS_KEY}
        }
      '';
      description = ''
        Caddy global config block. Defaults to Route53 DNS challenge with
        credentials and ACME email read from the environment file.

        To disable DNS challenge for a host (e.g. use HTTP challenge or no TLS),
        override this to "" and omit environmentFile. Caddy will fall back to
        HTTP-01 challenge or self-signed certs depending on your site blocks.
      '';
    };

    environmentFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Environment file with secrets for caddy's global config.
        Expected variables for the default globalConfig:
          ACME_EMAIL, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_REGION
      '';
    };

    configFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "External Caddyfile path (bypasses route generation)";
    };
  };
}
