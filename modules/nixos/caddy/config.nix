{ lib, config, pkgs, ... }:

let
  cfg = config.mine.caddy;

  # Generate virtualHosts from routes, trimming empty lines.
  routeVhosts = lib.mapAttrs
    (_: route: {
      extraConfig = lib.concatStringsSep "\n" (lib.filter (s: s != "") [
        (lib.optionalString route.compress "encode gzip zstd")
        route.extraConfig
        "reverse_proxy ${route.upstream}"
      ]);
    })
    cfg.routes;
in
{
  assertions = [{
    assertion = !(cfg.routes != { } && cfg.configFile != null);
    message = "mine.caddy: routes and configFile are mutually exclusive";
  }];

  services.caddy = lib.mkMerge [
    {
      enable = true;
      package = pkgs.caddy.withPlugins {
        plugins = [ "github.com/caddy-dns/route53@v1.6.2" ];
        hash = "sha256-/9c9b+S98V+eDj6mzb6KfAWWSBCrZoUzA1JDrMxuKQ0=";
      };
    }

    (lib.mkIf (cfg.configFile == null) {
      inherit (cfg) globalConfig;
      virtualHosts = routeVhosts;
    })

    (lib.mkIf (cfg.configFile != null) {
      inherit (cfg) configFile;
    })

    (lib.mkIf (cfg.environmentFile != null) {
      inherit (cfg) environmentFile;
    })
  ];
}
