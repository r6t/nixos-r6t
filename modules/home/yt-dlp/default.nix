{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.yt-dlp.enable =
        lib.mkEnableOption "enable yt-dlp in home-manager";
    };

    config = lib.mkIf config.mine.home.yt-dlp.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ yt-dlp ];
    };
}