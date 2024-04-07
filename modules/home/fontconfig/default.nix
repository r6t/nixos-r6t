{ lib, config, ... }: { 

    options = {
      mine.home.fontconfig.enable =
        lib.mkEnableOption "enable fontconfig in home-manager";
    };

    config = lib.mkIf config.mine.home.fontconfig.enable { 
      home-manager.users.r6t.fonts = {
        fontconfig.enable = true;
      };
    };
}