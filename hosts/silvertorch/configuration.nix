{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    # ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # troubleshooting external display ddc/ci brighness control
  hardware.i2c.enable = true;
  users.users.r6t.extraGroups = [ "i2c" ];

  networking = {
    firewall.allowedTCPPorts = [ 22 ];
    hostName = "silvertorch";
  };

  system.stateVersion = "23.11";

  mine = {
    flatpak = {
      bottles.enable = true;
      jellyfin-player.enable = true;
      protonup-qt.enable = true;
      retroarch.enable = true;
      steam.enable = true;
      supersonic.enable = true;
    };

    home = {
      alacritty.enable = true;
      atuin.enable = true;
      awscdk.enable = true;
      awscli.enable = true;
      bitwarden.enable = true;
      browsers.enable = true;
      fish.enable = true;
      fontconfig.enable = true;
      git.enable = true;
      home-manager.enable = true;
      kde-apps.enable = true;
      mpv.enable = true;
      nixvim.enable = true;
      python3.enable = true;
      ssh.enable = true;
      vscodium.enable = true;
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

