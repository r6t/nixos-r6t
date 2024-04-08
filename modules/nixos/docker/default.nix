{ lib, config, pkgs, ... }: { 

    options = {
      mine.docker.enable =
        lib.mkEnableOption "enable my standard rootless docker setup";
    };

    config = lib.mkIf config.mine.docker.enable { 
      virtualisation.docker = { 
        autoPrune.enable = true;
        daemon.settings = {
          data-root = "/home/r6t/docker-root";
        };
        enable = true;
        enableOnBoot = true;
        rootless = {
          enable = true;
          setSocketVariable = true;
        };
      };

      environment.systemPackages = with pkgs; [ docker-compose ];
    };
}