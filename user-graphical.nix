{ config, pkgs, ... }:
{
  home-manager.users.r6t = { pkgs, ...}: {
    home.file.".config/hypr/hyprland.conf".source = config/hypr/hyprland.conf;
    home.file.".config/hypr/hyprpaper.conf".source = config/hypr/hyprpaper.conf;
    home.file.".config/swaylock/config".source = config/swaylock/config;
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
      hyprpaper # wallpaper
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
	# ms-python.vscode-pylance # unfree
	redhat.vscode-yaml
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
        XDG_SESSION_TYPE = "wayland";
        QT_QPA_PLATFORM="wayland"; # maybe "wayland-egl"
	      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
    };
    programs.git = {
      enable = true;
      userName = "r6t";
      userEmail = "ryancast@gmail.com";
      extraConfig = {
        core = {
          editor = "nvim";
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
    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "aws" "git" "python" "thefuck" ];
        theme = "xiong-chiamiov-plus";
      };
    };
    home.homeDirectory = "/home/r6t";
    home.username = "r6t";
    home.stateVersion = "23.11";
  };
}
