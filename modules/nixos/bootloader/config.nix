{ lib, ... }:

{
  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = lib.mkDefault 10;
  };
  boot.loader.efi = {
    canTouchEfiVariables = true;
    efiSysMountPoint = "/boot";
  };
}
