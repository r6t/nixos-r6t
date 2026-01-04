{ lib, ... }:

{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "miniflux";

  # Match existing PostgreSQL data ownership (docker postgres UID 999)
  users.users.postgres.uid = lib.mkForce 999;

  services.postgresql = {
    # Point to Incus-mounted persistent storage
    dataDir = "/var/lib/postgresql/data";
  };

  services.miniflux = {
    enable = true;
    createDatabaseLocally = true;

    # Environment file for secrets (OAUTH2_CLIENT_SECRET, ADMIN_PASSWORD if needed)
    adminCredentialsFile = "/var/lib/miniflux/env";

    config = {
      LISTEN_ADDR = "0.0.0.0:84";
      BASE_URL = "https://miniflux.r6t.io";

      # OIDC configuration (secret in adminCredentialsFile)
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "67dcba05-b852-4827-bc8d-f8bba652b05d";
      OAUTH2_REDIRECT_URL = "https://miniflux.r6t.io/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://pid.r6t.io";
      OAUTH2_OIDC_PROVIDER_NAME = "PocketID";
      OAUTH2_USER_CREATION = 1;
      DISABLE_LOCAL_AUTH = 0;

      # Don't create admin on startup - using existing db
      CREATE_ADMIN = 0;
    };
  };

  networking.firewall.allowedTCPPorts = [ 84 ];
}
