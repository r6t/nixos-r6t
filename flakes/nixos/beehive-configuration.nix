{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    inputs.home-manager.nixosModules.home-manager
    # If you want to use modules from other flakes (such as nixos-hardware):
    # inputs.hardware.nixosModules.common-cpu-amd
    # inputs.hardware.nixosModules.common-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./beehive-hardware-configuration.nix
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
    config = {
      allowUnfree = true;
    };
  };

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      # Import your home-manager configuration
      r6t = import ../home-manager/home-shell.nix;
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

  environment.shells = with pkgs; [ zsh ]; # /etc/shells
  # System packages
  environment.systemPackages = with pkgs; [
     ansible
     awscli2
     curl
     fd
     git
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

  hardware.bluetooth.enable = false;

  networking.bridges.br0.interfaces = ["enp88s0"];
  networking.firewall.allowedTCPPorts = [ 22 5900 ];
  networking.hostName = "beehive";
  networking.interfaces.br0 = {
    useDHCP = true;
  };
  networking.networkmanager.enable = true;

  programs.zsh.enable = true;

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
  services.fwupd.enable = true; # Linux firmware updater
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
    layout = "us";
    xkbVariant = "";
  };

  services.openssh = {
    enable = true;
      # PermitRootLogin = "no";
      # PasswordAuthentication = true;
    };

  system.stateVersion = "23.11";

  users.users = {
    r6t = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = [
      ];
      extraGroups = [ "docker" "libvirtd" "networkmanager" "wheel"];
      shell = pkgs.zsh;
    };
  };

  # Containers
  virtualisation.docker = { 
    daemon.settings = {
      data-root = "/home/r6t/docker-root";
    };
    enable = false;
    enableOnBoot = false;
    rootless = {
      enable = false;
      setSocketVariable = false;
    };
  };
  virtualisation.libvirt = {
    enable = true;
    qemu.ovmf.enable = true;
  };
}
