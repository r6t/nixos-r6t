{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.vlc.enable =
        lib.mkEnableOption "enable vlc in home-manager";
    };

    config = lib.mkIf config.mine.home.vlc.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ vlc ];
    };
}