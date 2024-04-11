{ lib, config, pkgs, ... }: { 

    options = {
      mine.hypr.enable =
        lib.mkEnableOption "enable and configure my hypr desktop";
    };

    config = lib.mkIf config.mine.hypr.enable { 
      environment.systemPackages = with pkgs; [
        brightnessctl
        dconf
        gnome.gnome-font-viewer
        pamixer
        playerctl
        waybar
        wdisplays
        wl-clipboard
        wlogout
        xdg-utils
      ];

      programs.hyprland = {
        enable = true;
        xwayland.enable = true;
      };
      
      security.polkit.enable = true;

      services.xserver = {
        xkb = {
          layout = "us";
          variant = "";
        };
      };

      xdg.portal = {
        enable = true;
        wlr.enable = true;
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
        config = {
          common.default = ["gtk"];
        };
      };
    };
}