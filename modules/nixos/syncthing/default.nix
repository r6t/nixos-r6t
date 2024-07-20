{ lib, config, pkgs, ... }: { 

    options = {
    mine.syncthing.enable = lib.mkEnableOption "enable and configure my syncthing";
    };

    config = lib.mkIf config.mine.syncthing.enable { 
      services.syncthing = {
        enable = true;
        dataDir = "/home/r6t/icloud";
        openDefaultPorts = true;
        overrideDevices = false;
        overrideFolders = false;
        configDir = "/home/r6t/.config/syncthing";
        user = "r6t";
        group = "users";
        guiAddress = "0.0.0.0:8384";
        settings.gui = {
          user = "r6t"; 
        };
        serviceConfig = {
          ExecStartPre = "${pkgs.syncthing}/bin/syncthing generate --gui-password=$(cat ${config.sops.secrets."syncthing/creds/password".path}) --gui-user=r6t";
          # Ensure `User` and `Group` are set to run the command with correct permissions
          User = "r6t";
          Group = "users";
        };
      };
    };
}