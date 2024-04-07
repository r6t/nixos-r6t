{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.hyprland.enable =
        lib.mkEnableOption "enable hyprland environment config";
    };

    config = lib.mkIf config.mine.home.hyprland.enable { 
      home-manager.users.r6t = { 
        home = {
          file.".config/hypr/hyprland.conf".source = ../../../dotfiles/hypr/hyprland.conf;
        };
        
        home.sessionVariables = {
          MOZ_ENABLE_WAYLAND = 1;
          XDG_CURRENT_SESSION = "hyprland";
          XDG_SESSION_TYPE = "wayland";
          QT_QPA_PLATFORM="wayland"; # maybe "wayland-egl"
          QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
        };
      };
    };
}