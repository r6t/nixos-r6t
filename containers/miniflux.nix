{ ... }:

{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
  ];

  networking.hostName = "miniflux";

  services.miniflux = {
    enable = true;
    createDatabaseLocally = true;

    # Environment file for secrets (OAUTH2_CLIENT_SECRET)
    adminCredentialsFile = "/var/lib/miniflux/env";

    config = {
      LISTEN_ADDR = "0.0.0.0:8080";
      BASE_URL = "https://miniflux.r6t.io";

      # OIDC configuration (OAUTH2_CLIENT_SECRET in adminCredentialsFile)
      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "67dcba05-b852-4827-bc8d-f8bba652b05d";
      OAUTH2_REDIRECT_URL = "https://miniflux.r6t.io/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://pid.r6t.io";
      OAUTH2_OIDC_PROVIDER_NAME = "PocketID";
      OAUTH2_USER_CREATION = 1;
      DISABLE_LOCAL_AUTH = 0;

      # Don't create admin - importing existing users from backup
      CREATE_ADMIN = 0;
    };
  };

  # PostgreSQL dataDir on persistent storage (mounted by Incus)
  services.postgresql.dataDir = "/var/lib/postgresql/data";

  networking.firewall.allowedTCPPorts = [ 8080 ];
}
