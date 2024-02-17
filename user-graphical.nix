{ config, pkgs, ... }:
{
  home-manager.users.r6t = { pkgs, ...}: {
    home.file.".config/hypr/hyprland.conf".source = config/hypr/hyprland.conf;
    home.file.".config/waybar/config".source = config/waybar/config;
    home.packages = with pkgs; [
      betaflight-configurator
      bitwarden
      brave
      brightnessctl # display brightness
      dconf # hyprland support
      firefox-wayland
      freecad
      freerdp
      grim # screenshot functionality
      kate # KDE text editor
      kdiff3 # KDE utility
      krename # KDE utility
      krusader # KDE file manager
      libsForQt5.breeze-gtk # KDE Breeze theme
      libsForQt5.breeze-icons # KDE app icons
      libsForQt5.elisa # KDE music player
      libsForQt5.kio-extras # KDE support
      libsForQt5.polkit-kde-agent # KDE privlege escalation helper
      libsForQt5.qtwayland # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
      libsForQt5.qt5ct # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
      libnotify # reqd for mako
      mako # notification system developed by swaywm maintainer
      protonmail-bridge
      librewolf
      pamixer # pulseaudio controls
      playerctl # media keys
      remmina
      rofi-wayland
      slurp # screenshot functionality
      ungoogled-chromium
      virt-manager
      vlc
      webcord # Discord client
      xdg-utils # for opening default programs when clicking links
      waybar
      wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
      wdisplays # wayland display config
      wlogout
      wlr-randr # wayland
      youtube-dl
    ];
    programs.alacritty = {
      enable = true;
      settings = {
      font = {
        size = 14.0;
      };
      selection = {
        save_to_clipboard = true;
      };
      };
    };
    programs.thunderbird = {
      enable = true;
      package = pkgs.thunderbird;
      profiles.r6t = {
        isDefault = true;
      };
    };
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        yzhang.markdown-all-in-one
      ];
      userSettings = {
        "window.titleBarStyle" = "custom";
      };
    };
    home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
      	XDG_CURRENT_SESSION = "hyprland";
        QT_QPA_PLATFORM="wayland"; # maybe "wayland-egl"
	      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;

        # XDG_SESSION_TYPE = "wayland";
        # WAYLAND_DISPLAY="wayland-1";
        # GDK_BACKEND="wayland";
        # XDG_DATA_DIRS=/path/to/data_dirs:${XDG_DATA_DIRS};
        # XDG_CONFIG_DIRS=/path/to/config_dirs:${XDG_CONFIG_DIRS};
    };
  };
}