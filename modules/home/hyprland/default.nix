{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.hyprland.enable =
        lib.mkEnableOption "enable hyprland environment config";
    };

    config = lib.mkIf config.mine.home.hyprland.enable { 
      home-manager.users.r6t = { 
        home = {
          file.".config/hypr/hyprland.conf".source = dotfiles/hyprland.conf;
        };
        
        home.sessionVariables = {
          MOZ_ENABLE_WAYLAND = 1;
          XDG_CURRENT_SESSION = "hyprland";
          XDG_SESSION_TYPE = "wayland";
          __GLX_VENDOR_LIBRARY_NAME = "nvidia";
          LIBVA_DRIVER_NAME = "nvidia";
          GBM_BACKEND = "nvidia-drm";
          QT_QPA_PLATFORM="wayland";
          QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
          NIXOS_OZONE_WL = "1";
          QT_STYLE_OVERRIDE = "Breeze-Dark";
        };
      };
    };
}