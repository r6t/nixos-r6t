# r6t's nixos configuration
# Currently used to manage a single Framework laptop

{ config, pkgs, ... }:

{ imports =
    [ <home-manager/nixos>
      # <nixos-hardware/framework>

      # Include the results of the hardware scan.
      ./hardware-configuration.nix ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true; boot.loader.efi.canTouchEfiVariables = true;

  # Setup keyfile
  boot.initrd.secrets = { "/crypto_keyfile.bin" = null;
  };

  # Enable swap on luks
  boot.initrd.luks.devices."luks-f26077b3-1094-45f1-8c6e-07f7fee52e72".device = "/dev/disk/by-uuid/f26077b3-1094-45f1-8c6e-07f7fee52e72"; 
  boot.initrd.luks.devices."luks-f26077b3-1094-45f1-8c6e-07f7fee52e72".keyFile = "/crypto_keyfile.bin";

  # Networking
  networking.networkmanager.enable = true;
  networking.hostName = "mountainball"; # Define your hostname.
  # networking.wireless.enable = true; # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary networking.proxy.default = "http://user:password@proxy:port/"; networking.proxy.noProxy = 
  # "127.0.0.1,localhost,internal.domain";

  # Time zone.
  time.timeZone = "America/Los_Angeles";

  # Internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = { LC_ADDRESS = "en_US.UTF-8"; LC_IDENTIFICATION = "en_US.UTF-8"; LC_MEASUREMENT = "en_US.UTF-8"; LC_MONETARY = 
    "en_US.UTF-8"; LC_NAME = "en_US.UTF-8"; LC_NUMERIC = "en_US.UTF-8"; LC_PAPER = "en_US.UTF-8"; LC_TELEPHONE = "en_US.UTF-8"; LC_TIME = 
    "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true; services.xserver.desktopManager.plasma5.enable = true;

  # Get our flatpak on
  services.flatpak.enable = true;
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];

  # Configure keymap in X11
  services.xserver = { layout = "us"; xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true; hardware.pulseaudio.enable = false; security.rtkit.enable = true; services.pipewire = {
    enable = true; alsa.enable = true; alsa.support32Bit = true; pulse.enable = true;
    # If you want to use JACK applications, uncomment this jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default, no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager). services.xserver.libinput.enable = true;

  # "always enable the shell system-wide"
  programs.zsh.enable = true;

  # hyprland
  # programs.hyprland.enable = true;

  # /etc/shells the nixos way
  environment.shells = with pkgs; [ zsh ];

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.user = { isNormalUser = true; description = "user"; extraGroups = [ "networkmanager" "wheel" ]; shell = pkgs.zsh;
  #packages = with pkgs; [
  #    ansible
  #    firefox
  #    freetube
  #    kate
  #    ripgrep
  #  #  thunderbird
  #  ];
  };
  #home.username = "user"
  #home.homeDirectory = "/home/user"

  home-manager.users.user = { pkgs, ...}: {
    home.packages = [
      pkgs.alacritty
      pkgs.ansible
      pkgs.brave
      pkgs.firefox
      pkgs.freecad
      pkgs.freetube
      pkgs.kate
      pkgs.mullvad-vpn
      pkgs.librewolf
      pkgs.ripgrep
      pkgs.signal-desktop
      pkgs.ungoogled-chromium
      pkgs.virt-manager
      pkgs.vlc
    ];
    programs.git = {
      enable = true;
      userName = "r6t";
      userEmail = "ryancast@gmail.com";
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
    # programs.zsh = {
    #   enable = true;
    #   oh-my-zsh = {
    #     enable = true;
    #   }
    # };
    home.stateVersion = "23.05";
  };

  # List packages installed in system profile. To search, run: $ nix search wget
  environment.systemPackages = with pkgs; [
      curl
      jq
      neovim
      tree
      unzip
      wget
  ];

#  nixpkgs.config.allowUnfreePredicate = pkg:
#    builtins.elem (lib.getName pkg) [
#      "obsidian"
#    ];
  # Some programs need SUID wrappers, can be configured further or are started in user sessions. programs.mtr.enable = true; programs.gnupg.agent = {
  #   enable = true; enableSSHSupport = true;
  # };

  # List services that you want to enable:

  services.fwupd.enable = true;
  services.syncthing = {
    enable = true;
    dataDir = "/home/user"; # unused value
    openDefaultPorts = true;
    configDir = "/home/user/.config/syncthing";
    user = "user";
    group = "users";
    guiAddress = "0.0.0.0:8384";
  };
  services.mullvad-vpn.enable = false;

  # Enable the OpenSSH daemon. services.openssh.enable = true;

  # Open ports in the firewall. networking.firewall.allowedTCPPorts = [ ... ]; networking.firewall.allowedUDPPorts = [ ... ]; Or disable the firewall 
  # altogether. networking.firewall.enable = false;

  # This value determines the NixOS release from which the default settings for stateful data, like file locations and database versions on your 
  # system were taken. It‘s perfectly fine and recommended to leave this value at the release version of the first install of this system. Before 
  # changing this value read the documentation for this option (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
