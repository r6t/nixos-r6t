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
        22
        8096
        8920
        5201
        8080
        8384
        19999
        22000
        6595
        8888
        9090
        9999
        7878
        8686
        8989
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
    immich.enable = true;
    iperf.enable = true;
    localization.enable = true;
    netdata.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    nvidia.enable = true;
    open-webui.enable = true;
    paperless.enable = true;
    selfhost.enable = false;
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

