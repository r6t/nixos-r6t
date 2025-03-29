{ lib, config, pkgs, ... }:
{

  options = {
    mine.docker.enable =
      lib.mkEnableOption "enable my standard rootless docker setup";
  };

  config = lib.mkIf config.mine.docker.enable {
    virtualisation.docker = {
      autoPrune.enable = true;
      daemon.settings = {
        experimental = true;
        data-root = "/home/r6t/docker-root";
        ipv6 = true;
        fixed-cidr-v6 = "fdcb:ab14:ad77::/64";
        #	log-driver = "loki";
        #	log-opts = {
        #	  "loki-url" = "https://loki.r6t.io/loki/api/v1/push";
        #	  "max-size" = "10m";
        #	  "max-file" = "3";
      };
      enable = true;
      enableOnBoot = true;
    };
    environment.systemPackages = with pkgs; [ docker-compose ];
  };
}
