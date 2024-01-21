# r6t's NixOS configuration: manages a 13" Framework AMD laptop

{ config, pkgs, ... }:

{
  imports =
    [
      <home-manager/nixos>
      <nixos-hardware/framework/13-inch/7040-amd>
      ./hardware-configuration.nix
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-c19f0d35-ae1c-4379-a5e9-ac0ea8665118".device = "/dev/disk/by-uuid/c19f0d35-ae1c-4379-a5e9-ac0ea8665118";

  environment.shells = with pkgs; [ zsh ]; # /etc/shells
  # System packages
  environment.systemPackages = with pkgs; [
     alacritty
     curl
  #   dbus
     git
     lshw
     neovim
     wget
     unzip
  #   xdg-utils # for opening default programs when clicking links
  #   glib # gsettings
  #   dracula-theme # gtk theme
  #   gnome3.adwaita-icon-theme  # default gnome cursors
  #   swaybg
  #   swayidle
  #   swaylock-effects
  #   grim # screenshot functionality
  #   slurp # screenshot functionality
  #   rofi
  #   wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
  #   mako # notification system developed by swaywm maintainer
  #   wdisplays # tool to configure displays
     wlogout
     tree
     waybar
     wayland
  ];

 # hardware.bluetooth.enable = true;
 # hardware.bluetooth.settings = {
 #       General = {
 #       	Experimental = true;
 #       };
 # };

  # Internationalization
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  networking.networkmanager.enable = true;
  networking.hostName = "silvertorch"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  nix = {
    # NixOS garbage collection
    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than-60d";
    };
    settings = {
      auto-optimise-store = true;
    };
  };

  # System programs:
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.zsh.enable = true;

  # System security settings:
  security.pam.services.swaylock = {}; # required for swaylock-effects functionality
  # security.polkit.enable = true;

  # System services:
 # services.blueman.enable = true; # Bluetooth
 # services.pipewire = {
 #   enable = true;
 #   alsa.enable = true;
 #   pulse.enable = true;
 # };
  # xdg-desktop-portal works by exposing a series of D-Bus interfaces
  # known as portals under a well-known name
  # (org.freedesktop.portal.Desktop) and object path
  # (/org/freedesktop/portal/desktop).
  # The portal interfaces include APIs for file access, opening URIs,
  # printing and others.
 # services.dbus.enable = true;
 # services.flatpak.enable = true;
 # services.fprintd.enable = true;
 # services.fwupd.enable = true; # Linux firmware updater
 # services.mullvad-vpn.enable = true; # Mullvad desktop app
 # services.printing.enable = true; # CUPS print support
 # services.syncthing = {
 #   enable = true;
 #   dataDir = "/home/r6t/icloud";
 #   openDefaultPorts = true;
 #   overrideDevices = false;
 #   overrideFolders = false;
 #   configDir = "/home/r6t/.config/syncthing";
 #   user = "r6t";
 #   group = "users";
 #   guiAddress = "127.0.0.1:8384";
 # };
 # services.tailscale.enable = true;
  services.openssh.enable = true;
  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  sound.enable = true; # see services.pipewire

  system.stateVersion = "23.11"; # Inital version on system. Do not edit,

  time.timeZone = "America/Los_Angeles";

  # Users:
  users.users.r6t = {
    isNormalUser = true;
    description = "r6t";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };
  home-manager.users.r6t = { pkgs, ...}: {
   # home.file.".config/hypr/hyprland.conf".source = config/hypr/hyprland.conf;
   # home.file.".config/swaylock/config".source = config/swaylock/config;
   # home.file.".config/waybar/config".source = config/waybar/config;
    # home.file.".config/waybar/style.css".source = config/waybar/style.css;
   # home.file.".config/wlogout/layout".source = config/wlogout/layout;
    # home.file.".config/wlogout/style.css".source = config/wlogout/style.css;
    # home.file.".config/wal/templates/colors-hyprland.conf".source = config/wal/templates/colors-hyprland.conf;
    # home.file.".config/wal/templates/colors-rofi-pywal.rasi".source = config/wal/templates/colors-rofi-pywal.rasi;
    # home.file.".config/wal/templates/colors-waybar.css".source = config/wal/templates/colors-waybar.css;
    # home.file.".config/wal/templates/colors-wlogout.css".source = config/wal/templates/colors-hyprland.conf;
    # home.file."bin/swayidle_manager.sh" = {
    #   source = ./scripts/swayidle_manager.sh;
    #   executable = true;
    # };
    home.packages = with pkgs; [
      ansible
      awscli2
      betaflight-configurator
      bitwarden
      brave
      fd
      firefox-wayland
      freecad
      freerdp
 #     gvfs # for thunar
      kate
      kdiff3
      krename
      krusader # pro file manager
      libsForQt5.elisa
  #    mullvad-vpn
      neofetch
      nerdfonts
      nmap
      networkmanagerapplet
      nodejs # neovim
      ollama
      librewolf
      pciutils
      ripgrep
      remmina
      source-sans-pro
      thefuck
      tmux
      toybox
      tree-sitter # neovim
      ungoogled-chromium
      usbutils
      virt-manager
      vlc
      webcamoid
      wlr-randr # wayland
      youtube-dl
  #    xclip
  #    xfce.thunar # simple file manager
  #    xfce.thunar-archive-plugin
  #    xfce.thunar-media-tags-plugin
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
        cmp-buffer
        cmp-nvim-lsp
        cmp-nvim-lua
        cmp-path
        cmp_luasnip
        friendly-snippets
        harpoon
        indentLine
        # mini-nvim
        nvim-lspconfig # lsp-zero
        lsp-zero-nvim
        luasnip
        nvim-cmp
        nvim-treesitter.withAllGrammars
        nvim-treesitter-context
        plenary-nvim
        rose-pine
        telescope-nvim
        undotree
        vim-fugitive
        vim-nix
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
        require("r6t")
        require("r6t.remap")
        require("r6t.treesitter")
        vim.cmd('set clipboard=unnamedplus')
      '';
      extraPackages = [
        pkgs.luajitPackages.lua-lsp
        pkgs.nodePackages.bash-language-server
        pkgs.nodePackages.pyright
        pkgs.nodePackages.vim-language-server
        pkgs.nodePackages.yaml-language-server
        pkgs.rnix-lsp
      ];
    };
  #  programs.pywal.enable = false; # might be causing problems
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
    home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
        XDG_SESSION_TYPE = "wayland";
        WAYLAND_DISPLAY="wayland-0";
        GDK_BACKEND="wayland";
        QT_QPA_PLATFORM="wayland";
        #XDG_DATA_DIRS=/path/to/data_dirs:${XDG_DATA_DIRS};
        #XDG_CONFIG_DIRS=/path/to/config_dirs:${XDG_CONFIG_DIRS};

    };
    home.username = "r6t";
    home.stateVersion = "23.11";
    # services.mpris-proxy.enable = false; # Bluetooth audio media button passthrough makes media keys lag
  };

  # Desktop portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
