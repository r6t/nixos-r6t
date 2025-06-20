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
    hostName = "barrel";
  };

  system.stateVersion = "23.11";
  services.journald.extraConfig = "SystemMaxUse=500M";

  # Toggle modules
  mine = {
    home = {
      atuin.enable = true;
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
      ssh.enable = true;
    };

    alloy.enable = true;
    bootloader.enable = true;
    env.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    incus.enable = true;
    localization.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nvidia-cuda.enable = true;
    prometheus-node-exporter.enable = true;
    rdfind.enable = true;
    sops.enable = true;
    ssh.enable = true;
    sshfs.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    tpm.enable = true;
    user.enable = true;
  };
}
