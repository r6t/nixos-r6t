# r6t's NixOS configuration: AMD CPU + Nvidia GPU desktop

{ config, lib, pkgs, ... }:

{
  imports =
    [
      <home-manager/nixos>
      ./hardware-configuration.nix
    ];


  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-592f29d8-cde7-4065-b38a-f0cd025e03fd".device = "/dev/disk/by-uuid/592f29d8-cde7-4065-b38a-f0cd025e03fd";
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ]; # sleep/wake


  environment.sessionVariables = {
    # Electron hint
    NIXOS_OZONE_WL = "1";
    # Wayland Nvidia disappearing cursor fix
    WLR_NO_HARDWARE_CURSORS = "1";
  };
  environment.shells = with pkgs; [ zsh ]; # /etc/shells
  # System packages
  environment.systemPackages = with pkgs; [
     alacritty
     ansible
     awscli2
     curl
     dconf # hyprland support
     fd
     git
     gnome.gnome-keyring
     gnupg
     jdk # at least wayland hidpi cursor support
     libsecret
     lshw
     libnotify # mako support
     neovim
     neofetch
     nmap
     nodejs
     pciutils
     ripgrep
     wget
     unzip
     thefuck
     tmux
     # tree-sitter # neovim
     unzip
     usbutils
     xdg-utils # default apps for file types
     swww
     swayidle
     swaylock-effects
     grim # screenshots
     slurp # screenshots
     rofi-wayland # app launcher
     wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
     mako # notifications
     wdisplays # tool to configure displays
     wlogout
     tree
     waybar
     xwayland
     zip
  ];

  fonts.packages = with pkgs; [
     font-awesome
     hack-font
     nerdfonts
     source-sans-pro
  ];

  hardware.bluetooth.enable = true;
  # Experimental settings allow the os to read bluetooth device battery level
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
     };
  };


 # Nvidia GPU (unfree)
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
  };
  hardware.nvidia = {
 
    # Modesetting is required.
    modesetting.enable = true;
 
    # Nvidia power management. Experimental, and can cause sleep/suspend to fail.
    powerManagement.enable = true; # changed from default false
    # Fine-grained power management. Turns off GPU when not in use.
    # Experimental and only works on modern Nvidia GPUs (Turing or newer).
    powerManagement.finegrained = false;
 
    # Use the NVidia open source kernel module (not to be confused with the
    # independent third-party "nouveau" open source driver).
    # Support is limited to the Turing and later architectures. Full list of 
    # supported GPUs is at: 
    # https://github.com/NVIDIA/open-gpu-kernel-modules#compatible-gpus 
    # Only available from driver 515.43.04+
    # Currently alpha-quality/buggy, so false is currently the recommended setting.
    open = false;
 
    # Enable the Nvidia settings menu,
        # accessible via `nvidia-settings`.
    nvidiaSettings = true;
 
    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
   };

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
  networking.hostName = "mountainball"; # Define your hostname.
  networking.firewall.allowedTCPPorts = [ 22 ];
  # networking.firewall.allowedUDPPorts = [ ... ];

  nix = {
    # Required for Flakes
    package = pkgs.nix;
    # NixOS garbage collection
    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than-60d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
  };

  nixpkgs.config.allowUnfree = true;


  # System programs:
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.zsh.enable = true;

  # System security settings:
  security.pam.services.swaylock = {}; # required for swaylock-effects functionality
  security.polkit.enable = true; # hyprland support
  security.rtkit.enable = true; # sound

  # System services:
  services.blueman.enable = true; # Bluetooth
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    jack.enable = true;
  };
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
  services.openssh.enable = true;
  # Configure keymap in X11
  services.xserver = {
    # xkb.layout = "us";
    # xkb.Variant = "";
    videoDrivers = ["nvidia"];
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  sound.enable = true; # see services.pipewire

  system.stateVersion = "23.11"; # Inital version on system. Do not edit,

  time.timeZone = "America/Los_Angeles";

  # Users:
  users.users.r6t = {
    isNormalUser = true;
    description = "r6t";
    extraGroups = [ "docker" "networkmanager" "wheel" ];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };
  home-manager.users.r6t = { pkgs, ...}: {
    home.file.".config/hypr/hyprland.conf".source = config/hypr/hyprland.conf;
    home.file.".config/waybar/config".source = config/waybar/config;
    home.packages = with pkgs; [
      betaflight-configurator
      bitwarden
      brave
      brightnessctl # display brightness
      firefox-wayland
      freecad
      freerdp
      kate # KDE text editor
      kdiff3 # KDE utility
      krename # KDE utility
      krusader # KDE file manager
      libva # https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
      libsForQt5.breeze-gtk # KDE Breeze theme
      libsForQt5.breeze-icons # KDE app icons
      libsForQt5.elisa # KDE music player
      libsForQt5.polkit-kde-agent # KDE privlege escalation helper
      libsForQt5.qtwayland # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
      libsForQt5.qt5ct # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
      protonmail-bridge
      librewolf
      pamixer # pulseaudio controls
      playerctl # media keys
      remmina
      ungoogled-chromium
      virt-manager
      vlc
      webcord # Discord client
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
	XDG_CURRENT_SESSION = "hyprland";
        QT_QPA_PLATFORM="wayland"; # maybe "wayland-egl"
	QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;

        # XDG_SESSION_TYPE = "wayland";
        # WAYLAND_DISPLAY="wayland-1";
        # GDK_BACKEND="wayland";
        # XDG_DATA_DIRS=/path/to/data_dirs:${XDG_DATA_DIRS};
        # XDG_CONFIG_DIRS=/path/to/config_dirs:${XDG_CONFIG_DIRS};
    };
    home.username = "r6t";
    home.stateVersion = "23.11";
#    services.mpris-proxy.enable = false; # Bluetooth audio media button passthrough makes media keys lag
  };

# Containers
  virtualisation.docker = { 
    daemon.settings = {
      data-root = "/home/r6t/docker-root";
    };
    enable = true;
    enableOnBoot = true;
    enableNvidia = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Desktop portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk pkgs.xdg-desktop-portal-hyprland ];
  };
}
