{ lib, config, ... }: { 

    options = {
      mine.syncthing.enable =
        lib.mkEnableOption "enable and configure my syncthing";
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
          user = "rsyncthing";
          password = "syncthingpasswordtoreplace";
        };
      };
    };
}