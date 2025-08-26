{ lib, config, pkgs, ... }:

let
  # As of Aug 2025, Route 53 plugin is not compatible with latest Caddy
  caddy-overlay = super: {
    caddy = super.caddy.overrideAttrs rec {
      version = "2.9.1";
      src = super.fetchFromGitHub {
        owner = "caddyserver";
        repo = "caddy";
        rev = "v${version}";
      };
    };
  };

  # Re-import nixpkgs using the path from the existing pkgs set.
  # This creates a new, local package set with the overlay applied.
  pkgs-with-caddy-override = import pkgs.path {
    # maintain consistency with parent-level pkgs
    inherit (config.nixpkgs) config;
    inherit (pkgs) system;
    # apply overlay
    overlays = [ caddy-overlay ];
  };

in
{
  options.mine.caddy.enable =
    lib.mkEnableOption "enable caddy webserver";

  # I'm only running Caddy in LXCs where I map a persistent Caddyfile
  options.mine.caddy.configFile =
    lib.mkOption {
      type = lib.types.str;
      description = "Caddyfile path (not managed by nix)";
      default = "/etc/caddy/Caddyfile";
    };

  config = lib.mkIf config.mine.caddy.enable {
    services.caddy = {
      enable = true;
      inherit (config.mine.caddy) configFile;
      environmentFile = "/etc/caddy/caddy.env";
      package = pkgs-with-caddy-override.caddy.withPlugins {
        # Check if Caddy version workaround still necessary when updating
        plugins = [ "github.com/caddy-dns/route53@v1.5.1" ];
        hash = "sha256-dTj2ZG8ip0a9Z5YP7sLdW4gwC0yREGFOXQgPwGWUkm0=";
      };
    };
  };
}
