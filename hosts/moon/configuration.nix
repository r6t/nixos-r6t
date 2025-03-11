{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  time.timeZone = "Etc/UTC";
  networking = {
    hostName = "moon";
    enableIPv6 = true;
    firewall = {
      allowedTCPPorts = [ 22 ];
    };
  };

  system.stateVersion = "23.11";

  mine = {
    bolt.enable = true;
    bootloader.enable = true;
    bridge.enable = true;
    docker.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    grafana.enable = true;
    localization.enable = true;
    loki.enable = true;
    libvirtd.enable = true;
    moonstore.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    nvidia-cuda.enable = true;
    prometheus.enable = true;
    prometheus-node-exporter.enable = true;
    sops.enable = true;
    ssh.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;

    home = {
      awscli.enable = true;
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
      python3.enable = true;
    };
  };
}

