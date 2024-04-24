{ lib, config, pkgs, ... }: { 

    options = {
      mine.podman.enable =
        lib.mkEnableOption "enable podman";
    };

    config = lib.mkIf config.mine.podman.enable { 
      virtualisation.podman = { 
        autoPrune.enable = true;
        dockerSocket.enable = true;
        enable = true;
      };
    };
}