# r6t's nixos configuration
# Currently used to manage a single Framework laptop

{ config, pkgs, ... }:

{ imports =
    [ <home-manager/nixos>
      <nixos-hardware/framework>

      # Include the results of the hardware scan.
      ./hardware-configuration.nix ];

  ### NIXOS CONFIGURATION
  boot.loader.systemd-boot.enable = true; boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.secrets = { "/crypto_keyfile.bin" = null;
  };
  boot.initrd.luks.devices."luks-f26077b3-1094-45f1-8c6e-07f7fee52e72".device = "/dev/disk/by-uuid/f26077b3-1094-45f1-8c6e-07f7fee52e72"; 
  boot.initrd.luks.devices."luks-f26077b3-1094-45f1-8c6e-07f7fee52e72".keyFile = "/crypto_keyfile.bin";

  environment.shells = with pkgs; [ zsh ]; # /etc/shells

  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = false; # Just say no to pulseaudio

  networking.networkmanager.enable = true;
  networking.hostName = "mountainball";
  # networking.wireless.enable = true; # wpa_supplicant

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = { LC_ADDRESS = "en_US.UTF-8"; LC_IDENTIFICATION = "en_US.UTF-8"; LC_MEASUREMENT = "en_US.UTF-8"; LC_MONETARY = 
    "en_US.UTF-8"; LC_NAME = "en_US.UTF-8"; LC_NUMERIC = "en_US.UTF-8"; LC_PAPER = "en_US.UTF-8"; LC_TELEPHONE = "en_US.UTF-8"; LC_TIME = 
    "en_US.UTF-8";
  };

  programs.hyprland.enable = false;
  programs.zsh.enable = true;

  sound.enable = true; # Enable sound with pipewire

  security.rtkit.enable = true;

  time.timeZone = "America/Los_Angeles";

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk ];

  ### USER + APPLICATIONS
  # Probably should be managing the user itself via home-manager?
  users.users.user = { isNormalUser = true; description = "user"; extraGroups = [ "networkmanager" "wheel" ]; shell = pkgs.zsh;
  # packages managed via home-manager
  };
  #home.username = "user"
  #home.homeDirectory = "/home/user"

  home-manager.users.user = { pkgs, ...}: {
    home.packages = [
      pkgs.ansible
      pkgs.brave
      pkgs.firefox-wayland
      pkgs.freecad
      pkgs.freetube
      pkgs.kate
      pkgs.mullvad-vpn
      pkgs.neofetch
      pkgs.librewolf
      pkgs.ripgrep
      pkgs.signal-desktop
      pkgs.thefuck
      pkgs.ungoogled-chromium
      pkgs.virt-manager
      pkgs.vlc
      pkgs.youtube-dl

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
    home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
    };
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

  # Some programs need SUID wrappers, can be configured further or are started in user sessions. programs.mtr.enable = true; programs.gnupg.agent = {
  #   enable = true; enableSSHSupport = true;
  # };

  ### SERVICES:
  services.flatpak.enable = true;
  services.fwupd.enable = true; # Linux firmware updater
  services.mullvad-vpn.enable = false; # Mullvad desktop app
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default, no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  services.printing.enable = true; # CUPS print support
  services.syncthing = {
    enable = true;
    dataDir = "/home/user"; # unused value
    openDefaultPorts = true;
    configDir = "/home/user/.config/syncthing";
    user = "user";
    group = "users";
    guiAddress = "0.0.0.0:8384";
  };
  services.xserver.enable = true;
  services.xserver = { layout = "us"; xkbVariant = ""; }; # X11 keymap
  services.xserver.displayManager.sddm.enable = true; # KDE Plasma
  services.xserver.desktopManager.plasma5.enable = true; # KDE Plasma
  services.xserver.displayManager.defaultSession = "plasmawayland"; # KDE Plasma
  # services.xserver.libinput.enable = true; # Enable touchpad support (enabled default in most desktopManager).

  # Enable the OpenSSH daemon. services.openssh.enable = true;

  # Open ports in the firewall. networking.firewall.allowedTCPPorts = [ ... ]; networking.firewall.allowedUDPPorts = [ ... ]; Or disable the firewall 
  # altogether. networking.firewall.enable = false;

  # Before changing this value read the documentation for this option (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05";

}
