{ pkgs, ... }:

{
  boot.kernelModules = [
    "thunderbolt"
  ];
  services.hardware.bolt.enable = true;
  environment.systemPackages = with pkgs; [ bolt ];
}
