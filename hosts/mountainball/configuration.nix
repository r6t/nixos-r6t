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
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
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
  boot.initrd.luks.devices."luks-ca693f0d-4d0a-4eee-ba6a-fdc2db22dfb1".device = "/dev/disk/by-uuid/ca693f0d-4d0a-4eee-ba6a-fdc2db22dfb1";
  boot.kernelParams = [ "nvidia.NVreg_PreserveVideoMemoryAllocations=1" ]; # sleep/wake

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
     curl
     docker-compose
     fd
     git
     home-manager
     libva # https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
     lshw
     neovim
     neofetch
     nmap
     nodejs
     nvidia-docker
     pciutils
     ripgrep
     tmux
     unzip
     usbutils
     wget
     tree
  ];

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      noto-fonts-emoji
      font-awesome
      hack-font
      nerdfonts
      source-sans-pro
    ];
  };

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
    modesetting.enable = true;
    powerManagement.enable = false; # changed from default false (back to false for testing)
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  networking.hostName = "mountainball";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 3000 11434 ];

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
  services.fprintd.enable = false; # causing nix build error 3/22/24
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
    videoDrivers = ["nvidia"];
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
