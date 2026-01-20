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
        plugins = [ "github.com/caddy-dns/route53@v1.6.0-beta.2" ];
        hash = "sha256-4u+26crPiPxaQ5Rjg7xEi7O/4/bdwcqKcaR3W9nTp90=";
      };
    };
  };
}
