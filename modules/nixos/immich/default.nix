{ lib, config, pkgs, ... }:

let
  envFile = "/etc/immich/env/oidc.env";
  immichMediaDir = "/mnt/moonstore/immich/library";
  immichPort = 2283;
in

{
  options = {
    mine.immich.enable =
      lib.mkEnableOption "enable immich server";
  };
  config = lib.mkIf config.mine.immich.enable {

    systemd = {
      tmpfiles.rules = [
        "d /etc/immich 0750 root root -"
        "f ${envFile} 0440 root root -"
      ];
      services = {
        "immich-generate-env" = {
          wantedBy = [ "multi-user.target" ];
          before = [ "immich-server.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = pkgs.writeShellScript "generate-immich-env" ''
                                      set -euo pipefail
                                      echo "AUTHENTICATION_OIDC_CLIENT_ID=$(cat /run/secrets/immich/oidc_client_id)" > ${envFile}
                                      echo "AUTHENTICATION_OIDC_CLIENT_SECRET=$(cat /run/secrets/immich/oidc_client_secret)" >> ${envFile}
              		        echo "DB_PASSWORD=$(cat /run/secrets/immich/db_password)" >> ${envFile}
            '';
          };
        };
        immich-server.serviceConfig.EnvironmentFile = envFile;
      };
    };

    services.immich = {
      enable = true;
      mediaLocation = immichMediaDir;
      host = "0.0.0.0";
      port = immichPort;
      environment = {
        AUTHENTICATION_OIDC_ENABLED = "true";
        AUTHENTICATION_OIDC_ISSUER_URL = "https://pid.r6t.io";
        AUTHENTICATION_OIDC_AUTO_REGISTER = "true";
        AUTHENTICATION_OIDC_BUTTON_TEXT = "Login with Pocket ID";
        AUTHENTICATION_PASSWORD_ENABLED = "false";
      };
    };
  };
}
