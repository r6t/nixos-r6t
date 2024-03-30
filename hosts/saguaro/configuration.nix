{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}:

let
  inherit (inputs) ssh-keys;
in
 {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ./hardware-configuration.nix
    ../../modules/base-system.nix
  ];

  # apps modules
  mine.docker.enable = true;
  mine.netdata.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.zsh.enable = true;

  # system modules
  mine.env.enable = true;
  mine.fwupd.enable = true;
  mine.localization.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      # Import your home-manager configuration
      r6t = import ../../home-manager/home-shell.nix;
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.firewall.allowedTCPPorts = [ 
    22
    3000 # ollama-web
    8000 # paperless-ngx
    8080 # stirling-pdf
    8384 # syncthing
    19999 # netdata
    22000 # syncthing
    6595
    8888
    9090
    9999
    32400
    32469
    7878
    8686
    8989
    ];
  networking.firewall.allowedUDPPorts = [ 
    32400
    32469
    5353
    1900
    ];
  networking.hostName = "saguaro";
  networking.networkmanager.enable = true;

  system.stateVersion = "23.11";

  users.users = {
    r6t = {
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ ssh-keys.outPath ];
      extraGroups = [ "docker" "networkmanager" "wheel"];
      shell = pkgs.zsh;
    };
  };
}
