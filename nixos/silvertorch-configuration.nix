{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}:

let
  inherit (inputs) ssh-keys;
in
 {
  # You can import other NixOS modules here
  imports = [
    inputs.home-manager.nixosModules.home-manager

    # Hardware list: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
    inputs.hardware.nixosModules.framework-13-7040-amd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./silvertorch-hardware-configuration.nix
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
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      # Import your home-manager configuration
      r6t = import ../home-manager/home-graphical.nix;
    };
  };

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;


  nix = {
    # NixOS garbage collection
    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than-60d";
    };
    settings = {
      auto-optimise-store = true;
      experimental-features = "nix-command flakes";
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-9fc9c182-0bad-474f-a9bb-ee2e6aa1be50".device = "/dev/disk/by-uuid/9fc9c182-0bad-474f-a9bb-ee2e6aa1be50";

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
     home-manager
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

  fonts = {
    enableFontDir = true;
    fonts = with pkgs; [
      noto-fonts-emoji
      font-awesome
      hack-font
      nerdfonts
      source-sans-pro
    ];
  };

 # fonts.packages = with pkgs; [
 #    font-awesome
 #    hack-font
 #    nerdfonts
 #    source-sans-pro
 # ];

  hardware.bluetooth.enable = true;
  # Experimental settings allow the os to read bluetooth device battery level
  hardware.bluetooth.settings = {
    General = {
      Experimental = true;
     };
  };

  networking.hostName = "silvertorch";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };
  programs.zsh.enable = true;

  security.pam.services.swaylock = {}; # required for swaylock-effects functionality
  security.polkit.enable = true; # hyprland support
  security.rtkit.enable = true; # sound

  time.timeZone = "America/Los_Angeles";

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
  # Configure keymap in X11
  services.xserver = {
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  sound.enable = true; # see services.pipewire

  services.openssh = {
    enable = true;
      # PermitRootLogin = "no";
      # PasswordAuthentication = true;
    };

  system.stateVersion = "23.11";

  users.users = {
    r6t = {
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ ssh-keys.outPath ];
      # input group reqd for waybar
      extraGroups = [ "docker" "input" "networkmanager" "wheel"];
      shell = pkgs.zsh;
    };
  };

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
    wlr.enable = true;
    # gtk portal needed to make gtk apps happy
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
}
