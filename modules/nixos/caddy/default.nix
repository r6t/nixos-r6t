{ lib, config, pkgs, ... }:
{
  options.mine.caddy.enable =
    lib.mkEnableOption "enable caddy webserver";

  options.mine.caddy.configFile =
    lib.mkOption {
      type = lib.types.str;
      description = "Caddyfile path (not managed by nix)";
      default = "/etc/caddy/Caddyfile";
    };

  config = lib.mkIf config.mine.caddy.enable {
    services.caddy = {
      enable = true;
      environmentFile = "/etc/caddy/caddy.env";
      inherit (config.mine.caddy) configFile;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/route53@v1.6.0-beta.2" ];
        hash = "sha256-Xw9HVYcy4n/R+9uBY0ty1YvpR3NqUwWNE2MooepjkSA=";
      };
    };
  };
}
