{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.freecad.enable =
        lib.mkEnableOption "enable freecad in home-manager";
    };

    config = lib.mkIf config.mine.home.freecad.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ freecad ];
    };
}