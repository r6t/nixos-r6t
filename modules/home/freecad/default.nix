{ lib, config, pkgs, userConfig, ... }: { 

    options = {
      mine.home.freecad.enable =
        lib.mkEnableOption "enable freecad in home-manager";
    };

    config = lib.mkIf config.mine.home.freecad.enable { 
      home-manager.users.${userConfig.username}.home.packages = with pkgs; [ freecad ];
    };
}
