{ inputs, userConfig, ... }:

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
    hostName = "saguaro";
  };

  sops = {
    defaultSopsFile = "/home/r6t/git/sops-ryan/secrets.yaml";
    age.keyFile = "/home/r6t/.config/sops/age/keys.txt";
    validateSopsFiles = false;
  };

  system.stateVersion = "23.11";

  users.users.${userConfig.username}.linger = true;

  mine = {
    alloy.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    docker.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    incus.enable = true;
    iperf.enable = true;
    localization.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    prometheus-node-exporter.enable = true;
    sops.enable = true;
    ssh.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    thunderbay.enable = true;
    user.enable = true;

    home = {
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
      ssh.enable = true;
    };
  };
}

