{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.kde-apps.enable =
        lib.mkEnableOption "enable kde-apps in home-manager";
    };

    config = lib.mkIf config.mine.home.kde-apps.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [
        kate # KDE text editor
        kdiff3 # KDE utility
        krename # KDE utility
        krusader # KDE file manager
        libsForQt5.breeze-gtk # KDE Breeze theme
        libsForQt5.breeze-icons # KDE app icons
        libsForQt5.elisa # KDE music player
        libsForQt5.gwenview # KDE image viewer
        libsForQt5.kio-extras # KDE support
        libsForQt5.polkit-kde-agent # KDE privlege escalation helper
        libsForQt5.qtwayland # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
        libsForQt5.qt5ct # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
      ];
    };
}