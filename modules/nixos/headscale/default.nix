{ lib, config, userConfig, ... }:

let
  cfg = config.mine.headscale;
in
{
  options.mine.headscale = {
    enable = lib.mkEnableOption "Headscale server";
    serverUrl = lib.mkOption {
      type = lib.types.str;
      description = "Headscale endpoint";
    };
    baseDomain = lib.mkOption {
      type = lib.types.str;
      description = "MagicDNS internal domain";
    };
    overrideLocalDns = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Override system DNS";
    };
    enableCaddy = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable Caddy. Blocks mine.caddy if false";
    };
  };

  config = lib.mkIf cfg.enable {
    services.headscale = {
      enable = true;
      port = 8080; # default
      address = "127.0.0.1"; # caddy listens on 0/0 and proxies in
      group = "users";
      settings = {
        server_url = cfg.serverUrl;
        dns = {
          base_domain = cfg.baseDomain;
          override_local_dns = cfg.overrideLocalDns;
        };
      };
      user = userConfig.username;
    };
    mine.caddy.enable = cfg.enableCaddy;
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.enableCaddy [ 443 ];
  };
}
