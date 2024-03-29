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
    inputs.hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
    ../../modules/base-system.nix
    ../../modules/desktop-workstation.nix
  ];

  # apps modules
  mine.docker.enable = true;
  mine.flatpak.enable = true;
  mine.hypr.enable = true;
  mine.mullvad.enable = true;
  mine.netdata.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.zsh.enable = true;

  # system modules
  mine.bluetooth.enable = true;
  mine.bolt.enable = true;
  mine.env.enable = true;
  mine.fonts.enable = true;
  mine.fwupd.enable = true;
  mine.localization.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.printing.enable = true;
  mine.sound.enable = true;

  home-manager = {
    extraSpecialArgs = { inherit inputs outputs; };
    users = {
      # Import your home-manager configuration
      r6t = import ../../home-manager/home-graphical.nix;
    };
  };

  users.users = {
    r6t = {
      isNormalUser = true;
      openssh.authorizedKeys.keyFiles = [ ssh-keys.outPath ];
      # input group reqd for waybar
      extraGroups = [ "docker" "input" "networkmanager" "wheel"];
      shell = pkgs.zsh;
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.luks.devices."luks-9fc9c182-0bad-474f-a9bb-ee2e6aa1be50".device = "/dev/disk/by-uuid/9fc9c182-0bad-474f-a9bb-ee2e6aa1be50";

  networking.hostName = "silvertorch";
  networking.networkmanager.enable = true;
  networking.firewall.allowedTCPPorts = [ 22 ];

  system.stateVersion = "23.11";

}
