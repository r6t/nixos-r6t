{ config, lib, pkgs, ... }:

let
  oidcEnvFile = "/etc/karakeep/oidc.env";
in

{
  options = {
    mine.karakeep.enable =
      lib.mkEnableOption "enable karakeep server";
  };

  config = lib.mkIf config.mine.karakeep.enable {
    systemd.services.karakeep-generate-env = {
      description = "Generate .env file for Karakeep OIDC from /run/secrets";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "karakeep-gen-env" ''
                    set -euo pipefail
                    mkdir -p /etc/karakeep
                    cat > ${oidcEnvFile} <<EOF
          OAUTH_CLIENT_ID=$(cat /run/secrets/karakeep/oidc_client_id)
          OAUTH_CLIENT_SECRET=$(cat /run/secrets/karakeep/oidc_client_secret)
          OAUTH_REDIRECT_URL=$(cat /run/secrets/karakeep/oidc_redirect_url)
          EOF
                    chmod 600 ${oidcEnvFile}
        '';
      };
    };

    services.karakeep = {
      enable = true;
      environmentFile = oidcEnvFile;
      extraEnvironment = {
        NEXTAUTH_URL = "https://keep.r6t.io";
        OAUTH_WELLKNOWN_URL = "https://pid.r6t.io/.well-known/openid-configuration";
        OAUTH_PROVIDER_NAME = "Pocket-ID";
        DISABLE_PASSWORD_AUTH = "true";
        DISABLE_SIGNUPS = "true";
      };
    };
  };
}
