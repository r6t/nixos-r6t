{ config, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [ age sops ];
  sops = {
    inherit (config.mine.sops) defaultSopsFile;
    defaultSopsFormat = "yaml";
    age.keyFile = config.mine.sops.ageKeyFile;
    validateSopsFiles = false;
  };
}
