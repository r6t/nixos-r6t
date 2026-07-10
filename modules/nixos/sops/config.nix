{ lib, config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ age sops ];
  mine.sops.available = lib.mkDefault true;

  sops = {
    inherit (config.mine.sops) defaultSopsFile;
    defaultSopsFormat = "yaml";
    age.keyFile = config.mine.sops.ageKeyFile;
    validateSopsFiles = false;
  };
}
