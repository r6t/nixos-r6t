{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.element-desktop.enable =
        lib.mkEnableOption "enable element-desktop in home-manager";
    };

    config = lib.mkIf config.mine.home.element-desktop.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ element-desktop ];
    };
}