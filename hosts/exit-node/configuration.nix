{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  time.timeZone = "America/Los_Angeles";
  networking = {
    hostName = "exit-node";
    enableIPv6 = true;
  };

  system.stateVersion = "23.11";

  mine = {
    alloy.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    env.enable = true;
    exit-node-routing.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    localization.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    prometheus-node-exporter.enable = true;
    sops.enable = true;
    ssh.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;

    home = {
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
    };
  };
}

