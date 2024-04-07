{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}:

 {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # apps modules
  mine.docker.enable = true;
  mine.flatpak.enable = true;
  mine.hypr.enable = false; # TODO: make nvidia stuff modular
  mine.mullvad.enable = true;
  mine.netdata.enable = true;
  mine.ollama.enable = true;
  mine.ssh.enable = true;
  mine.steam.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.zsh.enable = true;

  # system modules
  mine.bluetooth.enable = false;
  mine.bolt.enable = false; # system doesn't have thunderbolt
  mine.env.enable = false; # TODO: make nvidia stuff modular
  mine.fonts.enable = true;
  mine.fwupd.enable = true;
  mine.localization.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.printing.enable = true;
  mine.sound.enable = true;
  mine.user.enable = true;


  mine.home.alacritty.enable = true;
  mine.home.apple-emoji.enable = true;
  mine.home.awscli.enable = true;
  mine.home.betaflight-configurator.enable = true;
  mine.home.bitwarden.enable = true;
  mine.home.brave.enable = true;
  mine.home.calibre.enable = true;
  mine.home.chromium.enable = true;
  mine.home.digikam.enable = true;
  mine.home.element-desktop.enable = true;
  mine.home.firefox.enable = true;
  mine.home.fontconfig.enable = true;
  mine.home.freecad.enable = true;
  mine.home.freerdp.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.hypridle.enable = true;
  mine.home.hyprland.enable = true;
  mine.home.hyprpaper.enable = true;
  mine.home.hyprpicker.enable = true;
  mine.home.kde-apps.enable = true;
  mine.home.librewolf.enable = true;
  mine.home.mako.enable = true;
  mine.home.neovim.enable = true;
  mine.home.obsidian.enable = true;
  mine.home.protonmail-bridge.enable = true;
  mine.home.python3.enable = true;
  mine.home.remmina.enable = true;
  mine.home.rofi.enable = true;
  mine.home.screenshots.enable = true;
  mine.home.signal-desktop.enable = true;
  mine.home.thunderbird.enable = true;
  mine.home.virt-manager.enable = true;
  mine.home.virt-viewer.enable = true;
  mine.home.vlc.enable = true;
  mine.home.vscodium.enable = true;
  mine.home.waybar.enable = true;
  mine.home.webcord.enable = true;
  mine.home.youtube-dl.enable = true;
  mine.home.zsh.enable = true;

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
     pciutils
     ripgrep
     tmux
     unzip
     usbutils
     wget
     tree
  ];

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

  networking.hostName = "silvertorch";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 3000 8080 11434 ]; # ssh ollama

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };

  security.pam.services.swaylock = {}; # required for swaylock-effects functionality
  security.polkit.enable = true; # hyprland support

  # Configure keymap in X11
  services.xserver = {
    videoDrivers = ["nvidia"];
    xkb = {
      layout = "us";
      variant = "";
    };
  };

  system.stateVersion = "23.11";

  # Desktop portal
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    config = {
      common.default = ["gtk"];
    };
  };
}