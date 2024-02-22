{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
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
  home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
  home.file.".config/hypr/hyprpaper.conf".source = ../dotfiles/hypr/hyprpaper.conf;
  home.file.".config/swaylock/config".source = ../dotfiles/swaylock/config;
  home.file.".config/waybar/config".source = ../dotfiles/waybar/config;

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
    hyprpaper # wallpaper
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
    mako # notification system developed by swaywm maintainer
    protonmail-bridge
    librewolf
    pamixer # pulseaudio controls
    playerctl # media keys
    remmina
    rofi-wayland
    slurp # screenshot functionality
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
  programs.git = {
    enable = true;
    userName = "r6t";
    userEmail = "ryancast@gmail.com";
    extraConfig = {
      core = {
        editor = "nvim";
        init = { defaultBranch = "main"; };
        pull = { rebase = false; };
      };
    };
    ignores = [
      ".DS_Store"
      "*.pyc"
    ];
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      rose-pine
    ];
    extraConfig = ''
      colorscheme rose-pine
      set number relativenumber
      set nowrap
      set nobackup
      set nowritebackup
      set noswapfile
    '';
    # extraLuaConfig goes to .config/nvim/init.lua, which cannot be managed as an individual file when using this
    extraLuaConfig = ''
    '';
    extraPackages = [
    ];
  };
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
      bbenoist.nix
      # continue.continue # https://github.com/NixOS/nixpkgs/pull/289289
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
      "window.titleBarStyle" = "custom";
    };
  };
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "aws" "git" "python" "thefuck" ];
      theme = "xiong-chiamiov-plus";
    };
    shellAliases = {
      "h" = "Hyprland";
      "gst" = "git status";
      "gd" = "git diff";
      "gds" = "git diff --staged";
    };
  };

  home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      XDG_CURRENT_SESSION = "hyprland";
      XDG_SESSION_TYPE = "wayland";
      QT_QPA_PLATFORM="wayland"; # maybe "wayland-egl"
      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
