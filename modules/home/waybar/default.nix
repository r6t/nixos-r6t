{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.waybar.enable =
        lib.mkEnableOption "enable waybar in home-manager";
    };

    config = lib.mkIf config.mine.home.waybar.enable { 
      home-manager.users.r6t.home = {
        packages = with pkgs; [ waybar ];
        file.".config/waybar/config".source = ../../../dotfiles/waybar/config;
        file.".config/waybar/style.css".source = ../../../dotfiles/waybar/style.css;
      };
    };
}