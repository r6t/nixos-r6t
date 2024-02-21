{ config, pkgs, ... }:
{
  environment.sessionVariables = {
    # Electron hint
    NIXOS_OZONE_WL = "1";
    QT_STYLE_OVERRIDE = "Breeze-Dark"; # maybe not needed 
    # Wayland Nvidia disappearing cursor fix
    WLR_NO_HARDWARE_CURSORS = "1";

  };
  environment.shells = with pkgs; [ zsh ]; # /etc/shells
  # System packages
  environment.systemPackages = with pkgs; [
     ansible
     awscli2
     curl
     fd
     git
     libva # https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
     lshw
     neovim
     neofetch
     nmap
     nodejs
     pciutils
     ripgrep
     thefuck
     tmux
     unzip
     usbutils
     wget
     tree
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

 # nixpkgs.config.allowUnfreePredicate = pkg:
 #   builtins.elem (lib.getName pkg) [
 #     # Add additional package names here
 #     "hello-unfree"
 #   ];
  
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
    layout = "us";
    xkbVariant = "";
  };

  sound.enable = true; # see services.pipewire

  system.stateVersion = "23.11"; # Inital version on system. Do not edit,

  time.timeZone = "America/Los_Angeles";

  # Containers
  virtualisation.docker = { 
    daemon.settings = {
      data-root = "/home/r6t/docker-root";
    };
    enable = true;
    enableOnBoot = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  # Desktop portal
  xdg.portal = {
    enable = true;
    # wlr.enable = true; maybe problem?
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}