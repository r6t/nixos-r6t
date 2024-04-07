{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.screenshots.enable =
        lib.mkEnableOption "enable screenshots in home-manager";
    };

    config = lib.mkIf config.mine.home.screenshots.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ grim slurp ];
    };
}