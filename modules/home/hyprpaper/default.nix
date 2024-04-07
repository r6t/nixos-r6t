{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.hyprpaper.enable =
        lib.mkEnableOption "enable hyprpaper in home-manager";
    };

    config = lib.mkIf config.mine.home.hyprpaper.enable { 
      home-manager.users.r6t.home = {
        packages = with pkgs; [ hyprpaper ];
        file.".config/hypr/hyprpaper.conf".source = ../../../dotfiles/hypr/hyprpaper.conf;
      };
    };
}