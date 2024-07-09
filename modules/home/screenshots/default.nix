{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.screenshots.enable =
        lib.mkEnableOption "enable screenshot utilites for tiling wm";
    };

    config = lib.mkIf config.mine.home.screenshots.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ grim slurp ];
    };
}