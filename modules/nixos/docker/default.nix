{ lib, config, pkgs, ... }:

{
  options.mine.docker.enable =
    lib.mkEnableOption "enable standard docker: used inside LXC w no gpu or rootless";

  config = lib.mkIf config.mine.docker.enable {
    virtualisation.docker = {
      enable = true;
      enableOnBoot = true;
      autoPrune.enable = true;
    };

    environment.systemPackages = [ pkgs.docker-compose ];
  };
}

