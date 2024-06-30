{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}:

 {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # system details
  networking.hostName = "photolab";
  networking.firewall.allowedTCPPorts = [ 
    22
    2283 # immich
    ];
  networking.firewall.allowedUDPPorts = [ 
    ];
  system.stateVersion = "23.11";
  
  # users.users.r6t.linger = true;

  # system modules
  mine.bolt.enable = true;
  mine.bootloader.enable = true;
  mine.docker.enable = true;
  mine.env.enable = true;
  mine.fwupd.enable = true;
  mine.localization.enable = true;
  mine.netdata.enable = true;
  mine.networkmanager.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.nvidia.enable = true;
  mine.selfhost.enable = false;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.thunderbay.enable = false;
  mine.user.enable = true;
  mine.zsh.enable = true;

  # home modules
  mine.home.awscli.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.python3.enable = true;
  mine.home.zsh.enable = true;
}
