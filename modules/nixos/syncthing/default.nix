{ lib, config, pkgs, ... }:

{
    options = {
    mine.syncthing.enable = lib.mkEnableOption "enable and configure my syncthing";
    };

  config = lib.mkIf config.mine.syncthing.enable {
    environment.systemPackages = with pkgs; [ xmlstarlet ];
    
      services.syncthing = {
        enable = true;
        dataDir = "/home/r6t/icloud";
        openDefaultPorts = true;
        configDir = "/home/r6t/.config/syncthing";
        overrideDevices = false;
        overrideFolders = false;
        user = "r6t";
        group = "users";
        guiAddress = "0.0.0.0:8384";
        settings.gui = {
        user = "r6t";
      };
      };

      systemd.services.syncthing.serviceConfig = {
        ExecStartPre = pkgs.writeScript "set-syncthing-password.sh" ''
          #! ${pkgs.runtimeShell}
          set -eux
          passwordPath=${config.sops.secrets."syncthing/creds/password".path}
          configXmlPath="/home/r6t/.config/syncthing/config.xml"
  
          xmlstarletCmd=${pkgs.xmlstarlet}/bin/xmlstarlet
  
          echo $PATH
          ls -l $xmlstarletCmd
          $xmlstarletCmd --version
  
          PASSWORD=$(cat $passwordPath)
          HASHED_PASSWORD=$(echo -n "$PASSWORD" | sha256sum | cut -d' ' -f1)
  
          # Count the <password> elements to determine if an update or insert is needed
          PASSWORD_COUNT=$($xmlstarletCmd sel -t -v "count(/configuration/gui/password)" $configXmlPath)
          
          if [ "$PASSWORD_COUNT" -gt 0 ]; then
            echo "Updating existing password"
            $xmlstarletCmd ed --inplace \
              -u "/configuration/gui/password" \
              -v "$HASHED_PASSWORD" \
              $configXmlPath
          else
            echo "Inserting new password element"
            $xmlstarletCmd ed --inplace \
              -s "/configuration/gui" -t elem -n "password" \
              -v "$HASHED_PASSWORD" \
              $configXmlPath
            $xmlstarletCmd ed --inplace \
              -s "/configuration/gui" -t elem -n "password" -v "$HASHED_PASSWORD" \
              $configXmlPath
          fi
          '';
          User = "r6t";
          Group = "users";
    };
  };
}