{ lib, config, pkgs, ... }:
{
  options.mine.caddy.enable =
    lib.mkEnableOption "enable caddy webserver";

  options.mine.caddy = {
    configFile =
      lib.mkOption {
        type = lib.types.str;
        description = "Caddyfile path (not managed by nix)";
        default = "/etc/caddy/Caddyfile";
      };
    environmentFile =
      lib.mkOption {
        type = lib.types.str;
        description = "Caddyfile path (not managed by nix)";
        default = "/etc/caddy/caddy.env";
      };
  };

  config = lib.mkIf config.mine.caddy.enable {
    services.caddy = {
      enable = true;
      inherit (config.mine.caddy) configFile;
      inherit (config.mine.caddy) environmentFile;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/route53@v1.6.0" ];
        hash = "sha256-Ye4u2y6xVDbveP5v1BHXIxlp/u+Y2SqMW5RJB9yy52Y=";
      };
    };
  };
}
