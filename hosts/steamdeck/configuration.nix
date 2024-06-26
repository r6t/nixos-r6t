{
  inputs,
  jovian,
  lib,
  config,
  pkgs,
  outputs,
  ...
}:

 {
  imports = [
    inputs.home-manager.nixosModules.home-manager-unstable
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # system details
  networking.hostName = "steamdeck";
  networking.firewall.allowedTCPPorts = [ 22 ];
  system.stateVersion = "23.11";

  # system modules
  mine.bootloader.enable = true;
  mine.env.enable = true;
  mine.localization.enable = true;
  mine.networkmanager.enable = true;
  mine.jovian.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.printing.enable = true;
  mine.sound.enable = true;
  mine.ssh.enable = true;
  mine.tailscale.enable = true;
  mine.user.enable = true;
  mine.zsh.enable = true;

  # home modules
  mine.home.alacritty.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.neovim.enable = true;
  mine.home.zsh.enable = true;
 }
