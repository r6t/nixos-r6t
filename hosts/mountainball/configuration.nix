{ inputs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.hardware.nixosModules.framework-13-7040-amd
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking.hostName = "mountainball";

  services.fprintd.enable = false;

  system.stateVersion = "23.11";

  time.timeZone = "America/Los_Angeles";

  # modules
  mine = {
    flatpak = {
      anki.enable = true;
      calibre.enable = true;
      element.enable = true;
      inkscape.enable = true;
      libreoffice.enable = true;
      picard.enable = true;
      proton-mail.enable = true;
      remmina.enable = true;
      zoom.enable = true;
    };

    home = {
      aider.enable = true;
      alacritty.enable = true;
      atuin.enable = true;
      bitwarden.enable = true;
      browsers.enable = true;
      crush.enable = true; # this just sets app config file. see devshells.nix 
      darktable.enable = true;
      drawio.enable = true;
      fish.enable = true;
      fontconfig.enable = true;
      freecad.enable = true;
      git.enable = true;
      home-manager.enable = true;
      hyprland.enable = false;
      kde-apps.enable = true;
      mako.enable = false;
      mpv.enable = true;
      nixvim.enable = true;
      obs-studio.enable = true;
      obsidian.enable = true;
      orca-slicer.enable = true;
      signal-desktop.enable = true;
      ssh.enable = true;
      teams-for-linux.enable = true;
      virt-viewer.enable = true;
      webcord.enable = true;
      zellij.enable = true;
    };

    alloy.enable = true;
    bluetooth.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    czkawka.enable = true;
    direnv.enable = true;
    ddc-i2c.enable = true;
    docker.enable = true;
    env.enable = true;
    fonts.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    hypr.enable = false;
    iperf.enable = true;
    kde.enable = true;
    localization.enable = true;
    mullvad.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    npm.enable = true;
    printing.enable = true;
    pinchflat.enable = true;
    prometheus-node-exporter.enable = true;
    rdfind.enable = true;
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
