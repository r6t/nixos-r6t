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

  boot.initrd.luks.devices."luks-9fc9c182-0bad-474f-a9bb-ee2e6aa1be50".device = "/dev/disk/by-uuid/9fc9c182-0bad-474f-a9bb-ee2e6aa1be50";
  # boot.binfmt.emulatedSystems = [ "aarch64-linux" ];

  time.timeZone = "America/Los_Angeles";

  networking = {
    hostName = "mountainball";
  };
  # troubleshooting external display ddc/ci brighness control
  hardware.i2c.enable = true;
  users.users.r6t.extraGroups = [ "i2c" ];

  system.stateVersion = "23.11";
  services.fprintd.enable = false;

  mine = {
    flatpak = {
      anki.enable = true;
      bottles.enable = false;
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
      retroarch.enable = true;
      steam.enable = true;
      supersonic.enable = true;
      zoom.enable = true;
    };

    home = {
      aider.enable = true;
      alacritty.enable = true;
      atuin.enable = true;
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
      signal-desktop.enable = true;
      ssh.enable = true;
      teams-for-linux.enable = true;
      virt-viewer.enable = true;
      vscodium.enable = false;
      webcord.enable = true;
      yt-dlp.enable = false;
      zellij.enable = true;
    };

    alloy.enable = true;
    bluetooth.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    czkawka.enable = true;
    docker.enable = true;
    direnv.enable = true;
    env.enable = true;
    fonts.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    kde.enable = true;
    localization.enable = true;
    libvirtd = {
      enable = true;
      enableDesktop = true;
      cpuVendor = "amd";
    };
    mullvad.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    ollama.enable = true;
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
