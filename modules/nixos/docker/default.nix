{ lib, config, pkgs, ... }:
{

  options = {
    mine.docker.enable =
      lib.mkEnableOption "enable docker";
  };

  config = lib.mkIf config.mine.docker.enable {
    virtualisation.docker = {
      autoPrune.enable = true;
      daemon.settings = {
        experimental = true;
        ipv6 = true;
      };
      enable = true;
      enableOnBoot = true;
    };
    environment.systemPackages = with pkgs; [ docker-compose ];
  };
}
