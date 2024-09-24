{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.kde-apps.enable =
        lib.mkEnableOption "enable kde-apps in home-manager";
    };

    config = lib.mkIf config.mine.home.kde-apps.enable { 
      home-manager.users.r6t = {
        home.packages = with pkgs; [
          kate # KDE text editor
          kdiff3 # KDE utility
          krename # KDE utility
          krusader # KDE file manager
          kdePackages.breeze # KDE Breeze theme
          kdePackages.breeze-gtk # KDE Breeze theme
          kdePackages.breeze-icons # KDE app icons
          kdePackages.elisa # KDE music player
          kdePackages.filelight # KDE disk utilization visualizer
          kdePackages.gwenview # KDE image viewer
          kdePackages.kdeconnect-kde # KDE Connect phone pairing
          kdePackages.kio-extras # KDE support
          kdePackages.krdc # KDE VNC + RDP client
          kdePackages.polkit-kde-agent-1 # KDE privlege escalation helper
          kdePackages.qtwayland # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
        ];

      };
    };
}
