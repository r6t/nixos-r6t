{ pkgs, ... }:

let
  envFile = "/var/lib/dawarich/.env";
in
{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  # Fixed upstream after the locked nixpkgs rev: gdalMinimal skips this test
  # because it requires netCDF, which the minimal build intentionally disables.
  nixpkgs.overlays = [
    (_: prev: {
      gdalMinimal = prev.gdalMinimal.overrideAttrs (old: {
        disabledTests = (old.disabledTests or [ ]) ++ [ "test_zarr_read_simple_sharding" ];
      });
    })
  ];

  networking = {
    hostName = "dawarich";
    firewall.allowedTCPPorts = [ 3000 ];
  };

  time.timeZone = "America/Los_Angeles";

  services.dawarich = {
    enable = true;
    configureNginx = false;
    localDomain = "geo.r6t.io";
    sidekiqThreads = 2;
    extraEnvFiles = [ envFile ];
    environment = {
      APPLICATION_PROTOCOL = "https";
      APPLICATION_URL = "https://geo.r6t.io";
      STORE_GEODATA = "false";
      PROMETHEUS_EXPORTER_ENABLED = "false";
      RAILS_LOG_TO_STDOUT = "true";
      WEB_CONCURRENCY = "1";

      OIDC_ISSUER = "https://pid.r6t.io";
      OIDC_REDIRECT_URI = "https://geo.r6t.io/users/auth/openid_connect/callback";
      OIDC_PROVIDER_NAME = "Pocket ID";
      OIDC_AUTO_REGISTER = "true";
      OIDC_PKCE_ENABLED = "false";
      ALLOW_EMAIL_PASSWORD_REGISTRATION = "false";
      ALLOW_EMAIL_PASSWORD_LOGIN = "false";
    };
  };

  systemd.services = {
    dawarich-env-check = {
      description = "Check Dawarich Pocket ID environment";
      before = [
        "dawarich-init-db.service"
        "dawarich-web.service"
        "dawarich-sidekiq-all.service"
      ];
      serviceConfig.Type = "oneshot";
      script = ''
        if [ ! -f ${envFile} ]; then
          echo "Missing ${envFile}; add OIDC_CLIENT_ID and OIDC_CLIENT_SECRET for Pocket ID." >&2
          exit 1
        fi

        if ! ${pkgs.gnugrep}/bin/grep -Eq '^OIDC_CLIENT_ID=.+$' ${envFile}; then
          echo "Missing OIDC_CLIENT_ID in ${envFile}." >&2
          exit 1
        fi

        if ! ${pkgs.gnugrep}/bin/grep -Eq '^OIDC_CLIENT_SECRET=.+$' ${envFile}; then
          echo "Missing OIDC_CLIENT_SECRET in ${envFile}." >&2
          exit 1
        fi
      '';
    };

    dawarich-init-db = {
      requires = [ "dawarich-env-check.service" ];
      after = [ "dawarich-env-check.service" ];
    };

    dawarich-web = {
      requires = [ "dawarich-env-check.service" ];
      after = [ "dawarich-env-check.service" ];
    };

    dawarich-sidekiq-all = {
      requires = [ "dawarich-env-check.service" ];
      after = [ "dawarich-env-check.service" ];
    };
  };
}
