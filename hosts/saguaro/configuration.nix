{ inputs, userConfig, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking = {
    hostName = "saguaro";
    firewall = {
      allowedTCPPorts = [
        89
        80
        86
        5252
        1080
        10080
        19999
        22
        2222
        22000
        5201
        6595
        7878
        8080
        8083
        5000
        8096
        8384
        8443
        8686
        8680
        8888
        8920
        8989
        9090
        9925
        9999
      ];
      allowedUDPPorts = [ 1900 7359 5353 ];
    };
  };

  system.stateVersion = "23.11";

  users.users.${userConfig.username}.linger = true;

  mine = {
    bolt.enable = true;
    bootloader.enable = true;
    docker.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    localization.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    sops.enable = true;
    ssh.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    thunderbay.enable = true;
    user.enable = true;

    home = {
      awscli.enable = true;
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
      python3.enable = true;
      yt-dlp.enable = true;
    };
  };
}

