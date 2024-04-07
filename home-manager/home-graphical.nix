{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:

let
  appleEmojiFont = pkgs.stdenv.mkDerivation rec {
    pname = "apple-emoji-linux";
    version = "16.4-patch.1";
    src = pkgs.fetchurl {
      url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/v${version}/AppleColorEmoji.ttf";
      sha256 = "15assqyxax63hah0g51jd4d4za0kjyap9m2cgd1dim05pk7mgvfm";
    };

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/share/fonts/apple-emoji
      cp ${src} $out/share/fonts/apple-emoji/AppleColorEmoji.ttf
    '';

    meta = {
      homepage = "https://github.com/samuelngs/apple-emoji-linux";
      description = "Apple Color Emoji font";
      license = pkgs.lib.licenses.unfree;
    };
  };
in

{
  imports = [
  ];

  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };


  home = {
    homeDirectory = "/home/r6t";
    stateVersion = "23.11";
    username = "r6t";
  };
  # Set dotfiles
  home.file.".config/hypr/hypridle.conf".source = ../dotfiles/hypr/hypridle.conf;
  home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
  home.file.".config/hypr/hyprlock.conf".source = ../dotfiles/hypr/hyprlock.conf;
  home.file.".config/hypr/hyprpaper.conf".source = ../dotfiles/hypr/hyprpaper.conf;
  home.file.".config/waybar/config".source = ../dotfiles/waybar/config;
  home.file.".config/waybar/style.css".source = ../dotfiles/waybar/style.css;
  home.file.".local/share/rofi/themes/rounded-common.rasi".source = ../dotfiles/rofi/themes/rounded-common.rasi;
  home.file.".local/share/rofi/themes/rounded-purple-dark.rasi".source = ../dotfiles/rofi/themes/rounded-purple-dark.rasi;

  home.packages = with pkgs; [
    appleEmojiFont # see let block
    awscli2
    betaflight-configurator
    bitwarden
    brave
    brightnessctl # display brightness
    calibre # ebook manager
    dconf # hyprland support
    digikam # photo manager
    element-desktop # matrix client
    firefox-wayland
    freecad
    freerdp
    gnome.gnome-font-viewer
    grim # screenshots
    hypridle
    hyprlock
    hyprpaper # wallpaper
    hyprpicker # color picker
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
    libnotify # reqd for mako
    mako # notifications
    mellowplayer # music streaming
    obsidian # best notes app ever
    protonmail-bridge
    python3
    python311Packages.boto3
    python311Packages.pip
    python311Packages.troposphere
    python311Packages.jq
    python311Packages.yq
    librewolf
    pamixer # pulseaudio controls
    playerctl # media keys
    remmina
    signal-desktop
    slurp # screenshots
    swaylock-effects # lock screen
    ungoogled-chromium
    virt-manager
    virt-viewer
    vlc
    webcord # Discord client
    xdg-utils # for opening default programs when clicking links
    waybar
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    wdisplays # wayland display config
    wlogout # wayland logout shortcuts
    wlr-randr # wayland
    youtube-dl
  ];

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
      bbenoist.nix
      continue.continue
      dracula-theme.theme-dracula
      ms-azuretools.vscode-docker
      ms-python.isort
      ms-python.python
      ms-python.vscode-pylance # unfree
      redhat.vscode-yaml
      vscodevim.vim
      yzhang.markdown-all-in-one
    ];
    userSettings = {
      "editor.fontFamily" = "Hack Nerd Font, Noto Color Emoji";
      "editor.fontSize" = 14;
      "window.titleBarStyle" = "custom";
      "merge-conflict.autoNavigateNextConflict.enabled" = true;
      "redhat.telemetry.enabled" = false;
    };
  };
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "aws" "git" "python" ];
      theme = "xiong-chiamiov-plus";
    };
    shellAliases = {
      "h" = "Hyprland";
      "gst" = "git status";
      "gd" = "git diff";
      "gds" = "git diff --staged";
    };
  };

  fonts = {
    fontconfig.enable = true;
  };

  home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      XDG_CURRENT_SESSION = "hyprland";
      XDG_SESSION_TYPE = "wayland";
      QT_QPA_PLATFORM="wayland"; # maybe "wayland-egl"
      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
  };

  services.kdeconnect.enable = true; 
  services.kdeconnect.indicator = true; 

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
