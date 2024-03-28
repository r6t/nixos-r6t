{ lib, config, ... }: { 

    options = {
      mine.hypr.enable =
        lib.mkEnableOption "enable and configure my hypr apps";
    };

    config = lib.mkIf config.mine.hypr.enable { 
      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      
      security.pam.services.swaylock = {}; # required for swaylock-effects functionality
      security.polkit.enable = true; # hyprland authentication support

      # Configure keymap in X11
      services.xserver = {
        xkb = {
          layout = "us";
          variant = "";
        };
      };

      # Desktop portal
      xdg.portal = {
        enable = true;
        wlr.enable = true;
        # gtk portal needed to make gtk apps happy
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };
    };
}