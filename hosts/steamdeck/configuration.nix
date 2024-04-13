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
  networking.hostName = "steamdeck";
  networking.firewall.allowedTCPPorts = [ 22 ];
  system.stateVersion = "23.11";

  # jovian modules
  jovian.devices.steamdeck.enable = true;

  # system modules

  # home modules
 }