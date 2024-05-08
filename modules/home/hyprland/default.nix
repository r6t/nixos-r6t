{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.hyprland.enable =
        lib.mkEnableOption "enable hyprland with flatpak support";
    };

    config = lib.mkIf config.mine.home.hyprland.enable { 
      home-manager.users.r6t = { 
        home = {
          file.".config/hypr/hyprland.conf".source = dotfiles/hyprland.conf;
        };
        
        home.sessionVariables = {
          MOZ_ENABLE_WAYLAND = 1;
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORM="wayland";
          QT_QPA_PLATFORMTHEME="qt5ct";
          QT_STYLE_OVERRIDE = "Breeze-Dark";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
          XDG_CURRENT_SESSION = "hyprland";
          XDG_DATA_DIRS = "$XDG_DATA_DIRS:/usr/share:/var/lib/flatpak/exports/share:$HOME/.local/share/flatpak/exports/share";
        };
      };
    };
}