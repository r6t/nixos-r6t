{ lib, config, inputs, pkgs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  time.timeZone = "America/Los_Angeles";

  networking = {
    hostName = "silvertorch";
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.kdePackages.xdg-desktop-portal-kde ];
    config.common.default = "kde";
  };

  environment.systemPackages = with pkgs; [
    gamescope
    gamemode
    mangohud
  ];

  swapDevices = [
    { device = "/swapfile";
      size = 4096; # 4GB swap file - adequate for most desktop uses
    }
  ];

 nixpkgs.config.nvidia.acceptLicense = true;

 system.stateVersion = "23.11";
  services.fprintd.enable = false;

  mine = {
    flatpak = {
      anki.enable = true;
      calibre.enable = true;
      deezer.enable = true;
      element.enable = true;
      inkscape.enable = true;
      jellyfin-player.enable = true;
      libreoffice.enable = true;
      picard.enable = true;
      proton-mail.enable = true;
      protonup-qt.enable = true;
      remmina.enable = true;
      steam.enable = true;
      supersonic.enable = true;
      zoom.enable = true;
    };

    home = {
      alacritty.enable = true;
      atuin.enable = true;
      awscdk.enable = true;
      awscli.enable = true;
      bitwarden.enable = true;
      browsers.enable = true;
      darktable.enable = true;
      drawio.enable = true;
      fish.enable = true;
      fontconfig.enable = true;
      freecad.enable = true;
      git.enable = true;
      home-manager.enable = true;
      kde-apps.enable = true;
      mpv.enable = true;
      nixvim.enable = true;
      obsidian.enable = true;
      obs-studio.enable = true;
      python3.enable = true;
      signal-desktop.enable = true;
      ssh.enable = true;
      virt-viewer.enable = true;
      webcord.enable = true;
      yt-dlp.enable = true;
      zellij.enable = true;
    };

    bluetooth.enable = true;
    bootloader.enable = true;
    czkawka.enable = true;
    docker.enable = true;
    env.enable = true;
    fonts.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    kde.enable = true;
    localization.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    nvidia-open.enable = false;
    printing.enable = true;
    prometheus-node-exporter.enable = true;
    rdfind.enable = true;
    scansnap.enable = true;
    sops.enable = true;
    sound.enable = true;
    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;
    v4l-utils.enable = true;
  };
}
