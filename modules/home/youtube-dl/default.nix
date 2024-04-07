{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.youtube-dl.enable =
        lib.mkEnableOption "enable youtube-dl in home-manager";
    };

    config = lib.mkIf config.mine.home.youtube-dl.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ youtube-dl ];
    };
}