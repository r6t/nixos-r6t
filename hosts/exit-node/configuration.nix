{
  inputs,
  ...
}:

 {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # system details
  networking.hostName = "exit-node";
  networking = {
    enableIPv6 = true;
  };

  system.stateVersion = "23.11";

  # system modules
  mine.bolt.enable = true;
  mine.bootloader.enable = true;
  mine.docker.enable = false;
  mine.env.enable = true;
  mine.exit-node-routing.enable = true;
  mine.fwupd.enable = true;
  mine.fzf.enable = true;
  mine.localization.enable = true;
  mine.netdata.enable = true;
  mine.networkmanager.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.sops.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.user.enable = true;

  # home modules
  mine.home.awscli.enable = true;
  mine.home.fish.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.nixvim.enable = true;
  mine.home.python3.enable = true;
}
