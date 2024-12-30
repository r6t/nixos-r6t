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

  networking = {
    firewall.allowedTCPPorts = [ 22 ];
    hostName = "mountainball";
    networkmanager.ensureProfiles.profiles."Thunderbolt-Network" = {
      connection = {
        id = "Thunderbolt Network";
        type = "ethernet";
        interface-name = "enp100s0";
      };
      ethernet.mtu = 9000;
      ipv4.method = "auto";
      ipv6.method = "auto";
    };
  };

  system.stateVersion = "23.11";
  services.fprintd.enable = false;

  mine = {
    flatpak = {
      bottles.enable = true;
      deezer.enable = true;
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
      alacritty.enable = true;
      atuin.enable = true;
      awscdk.enable = true;
      awscli.enable = true;
      betaflight-configurator.enable = true;
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
      super-productivity.enable = true;
      virt-viewer.enable = true;
      vscodium.enable = true;
      webcord.enable = true;
      yt-dlp.enable = true;
      zellij.enable = true;
    };

    bluetooth.enable = true;
    bolt.enable = true;
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
    mullvad.enable = true;
    netdata.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    printing.enable = true;
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

