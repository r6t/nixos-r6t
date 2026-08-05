{ pkgs, userConfig, ... }:
{
  boot.kernelModules = [
    "sg"
  ];
  home-manager.users.${userConfig.username}.home.packages = with pkgs; [ makemkv ];
  users.users.${userConfig.username}.extraGroups = [ "cdrom" ];
}
