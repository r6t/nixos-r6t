{ lib, config, pkgs, ... }:

{
    options = {
    mine.syncthing.enable = lib.mkEnableOption "enable and configure my syncthing";
    };

  config = lib.mkIf config.mine.syncthing.enable {
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
        password = "$2a$10$uXPwWF.DUVjwRg0BNQ9bbOHAvlr3.KHU1qDRGa4Oontm8gS1kzHre";
      };
      };
  };
}