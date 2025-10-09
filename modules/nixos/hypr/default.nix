{ lib, config, pkgs, ... }: {

  options = {
    mine.hypr.enable =
      lib.mkEnableOption "enable hypr desktop";
  };

  config = lib.mkIf config.mine.hypr.enable {
    environment.systemPackages = with pkgs; [
      adwaita-icon-theme
      blueman
      brightnessctl
      dconf
      gnome-font-viewer
      grim # Screenshot utility
      hyprland-protocols
      hyprland-qt-support
      hyprland-qtutils
      hyprgraphics
      hyprpicker # Color picker
      hyprutils
      kdePackages.breeze
      kdePackages.breeze-gtk # For GTK app consistency
      kdePackages.breeze-icons
      pamixer
      playerctl
      qt6ct
      slurp # Screen region selector
      waybar
      wayland
      wayland-protocols
      wayland-utils
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
      extraPortals = [ pkgs.xdg-desktop-portal-hyprland pkgs.xdg-desktop-portal-gtk ];
      config = {
        common.default = [ "gtk" ];
      };
    };
  };
}
