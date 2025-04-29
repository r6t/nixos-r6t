{ inputs, pkgs, ... }:

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

  swapDevices = [
    {
      device = "/swapfile";
      size = 4096;
    }
  ];

  system.stateVersion = "23.11";
  services.journald.extraConfig = "SystemMaxUse=500M";
  services.fprintd.enable = false;

  # Toggle modules
  mine = {
    flatpak = {
      anki.enable = true;
      calibre.enable = true;
      deezer.enable = true;
      element.enable = true;
      inkscape.enable = true;
      jellyfin-player.enable = true;
      kamoso.enable = true;
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
      bitwarden.enable = true;
      browsers.enable = true;
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
      signal-desktop.enable = true;
      ssh.enable = true;
      virt-viewer.enable = true;
      webcord.enable = true;
      zellij.enable = true;
    };

    alloy.enable = true;
    bootloader.enable = true;
    bluetooth.enable = true;
    czkawka.enable = true;
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
    nvidia-open.enable = true;
    ollama-cuda.enable = true;
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
    tpm.enable = true;
    user.enable = true;
    v4l-utils.enable = true;
  };
}
