# r6t's NixOS configuration: Intel NUC 11th-gen, utility VM server

{ config, pkgs, ... }:
{
  imports =
    [
      <home-manager/nixos>
      ./hardware-configuration.nix
      ./user.nix
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  environment.sessionVariables = {
  };
  environment.shells = with pkgs; [ zsh ]; # /etc/shells
  # System packages
  environment.systemPackages = with pkgs; [
     ansible
     awscli2
     curl
     fd
     git
     libvirt
     lshw
     neovim
     neofetch
     nmap
     nodejs
     pciutils
     qemu_kvm
     ripgrep
     thefuck
     tmux
     tree
     unzip
     usbutils
     virt-manager
     virt-viewer
     wget

  ];

  hardware.bluetooth.enable = false;

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
  networking.hostName = "beehive"; # Define your hostname.
  networking.bridges.br0.interfaces = ["enp88s0"];
  networking.interfaces.br0 = {
    useDHCP = true;
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  networking.firewall.allowedTCPPorts = [ 22 5900 ];
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
  programs.zsh.enable = true;

  # System security settings:

  # System services:
  services.fwupd.enable = true; # Linux firmware updater
  services.syncthing = {
    enable = true;
    dataDir = "/home/r6t/Sync";
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

  sound.enable = false;

  system.stateVersion = "23.11"; # Inital version on system. Do not edit,

  time.timeZone = "America/Los_Angeles";

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu.ovmf.enable = true;
    };
  };

}
