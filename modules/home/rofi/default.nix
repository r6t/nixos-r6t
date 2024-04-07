{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.rofi.enable =
        lib.mkEnableOption "enable rofi in home-manager";
    };

    config = lib.mkIf config.mine.home.rofi.enable { 
      home-manager.users.r6t = {
        programs.rofi = {
          cycle = true;
          enable = true;
          package = pkgs.rofi-wayland;
          plugins = [
            pkgs.rofi-calc
            pkgs.rofi-emoji
          ];
          theme = "/home/r6t/.local/share/rofi/themes/rounded-purple-dark.rasi";
        };

        home.file.".local/share/rofi/themes/rounded-common.rasi".source = ../../../dotfiles/rofi/themes/rounded-common.rasi;
        home.file.".local/share/rofi/themes/rounded-purple-dark.rasi".source = ../../../dotfiles/rofi/themes/rounded-purple-dark.rasi;
      };
    };
}