{ config, pkgs, lib, userConfig, ... }:
{
  imports = [
    ./r6-tailnet-base.nix
    ../modules/nixos/caddy/default.nix
  ];
  #  mine.caddy.enable = true;
  services.caddy = {
    enable = true;
    # environmentFile = 
  };
  security.acme = {
    acceptTerms = true;
    defaults.email = "domains@r6t.io";
    certs."r6t.io" = {
      dnsProvider = "route53";
      environmentFile = "/run/secrets/route53.env";
    };
  };
  # Systemd dependencies
  systemd.services.jellyfin.after = [ "tailscale.service" ];
}

