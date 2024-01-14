# r6t's nixos configuration
# Manages a single Framework laptop

{ config, pkgs, ... }:
 
{
  imports =
    [
      <home-manager/nixos> 
      <nixos-hardware/framework/13-inch/7040-amd>
      ./hardware-configuration.nix
    ];
 
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.initrd.luks.devices."luks-049bd9e8-8c17-49ab-ac53-b01a796f8466".device = "/dev/disk/by-uuid/049bd9e8-8c17-49ab-ac53-b01a796f8466";
  networking.hostName = "silvertorch"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  environment.shells = with pkgs; [ zsh ]; # /etc/shells

  hardware.bluetooth.enable = true;
  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
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

  programs.zsh.enable = true;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  sound.enable = true; # see services.pipewire

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };


  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.r6t = {
    isNormalUser = true;
    description = "r6t";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };
 
  home-manager.users.r6t = { pkgs, ...}: {
    home.file.".config/hypr/hyprland.conf".source = ./config/hypr/hyprland.conf;
    home.file.".config/waybar/config".source = ./config/waybar/config;
    home.file.".config/waybar/style.css".source = ./config/waybar/style.css;
    home.packages = with pkgs; [
      ansible
      awscli2
      betaflight-configurator
      blueman # bluetooth
      brave
      fd
      firefox-wayland # wayland
      freecad
      freerdp
      kate
      kdiff3
      krename
      krusader
      libsForQt5.elisa
      lshw
      mullvad-vpn
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
      xclip
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
    };
    home.username = "r6t";
    home.stateVersion = "23.11";
    services.mpris-proxy.enable = false; # Bluetooth audio media button passthrough makes media keys lag
  };
 
  # Base system packages
  environment.systemPackages = with pkgs; [
     neovim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
     wget
     git
     curl
     unzip
     alacritty # gpu accelerated terminal
  #   dbus   # make dbus-update-activation-environment available in the path
  #   dbus-sway-environment
  #   configure-gtk
     waybar
     wayland
     xdg-utils # for opening default programs when clicking links
  #   glib # gsettings
  #   dracula-theme # gtk theme
  #   gnome3.adwaita-icon-theme  # default gnome cursors
     swaybg
     swayidle
     swaylock-effects
     grim # screenshot functionality
     slurp # screenshot functionality
     rofi
     wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
     mako # notification system developed by swaywm maintainer
     wdisplays # tool to configure displays
     wlogout
     tree
  ];
 
  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
 
  # List services that you want to enable:
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };
  # xdg-desktop-portal works by exposing a series of D-Bus interfaces
  # known as portals under a well-known name
  # (org.freedesktop.portal.Desktop) and object path
  # (/org/freedesktop/portal/desktop).
  # The portal interfaces include APIs for file access, opening URIs,
  # printing and others.
#  services.dbus.enable = true;
#  xdg.portal = {
#    enable = true;
#    wlr.enable = true;
#    # gtk portal needed to make gtk apps happy
#    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
#  };
#  programs.sway = {
#    enable = true;
#    wrapperFeatures.gtk = true;
#  };
  services.flatpak.enable = true;
  services.fprintd.enable = true;
  services.fwupd.enable = true; # Linux firmware updater
  services.mullvad-vpn.enable = true; # Mullvad desktop app
  services.printing.enable = true; # CUPS print support
  services.syncthing = {
    enable = true;
    dataDir = "/home/r6t/icloud";
    openDefaultPorts = true;
    overrideDevices = false;
    overrideFolders = false;
    configDir = "/home/r6t/.config/syncthing";
    user = "r6t";
    group = "users";
    guiAddress = "127.0.0.1:8384";
  };
  services.tailscale.enable = true;
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
 
  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
 
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
 
}
