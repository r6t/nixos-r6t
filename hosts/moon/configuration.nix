{ inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking = {
    hostName = "moon";
    enableIPv6 = true;
    firewall = {
      allowedTCPPorts = [
	100
	11000
	2283
	3000
	3003
	443
	80
	8080
	8123
	85
	8888
        11434
        22
        8123
        8443
        8888
      ];
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
    localization.enable = true;
    libvirtd.enable = true;
    moonstore.enable = true;
    netdata.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    nvidia.enable = true;
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

