{ lib, config, pkgs, ... }: { 

    options = {
      mine.bolt.enable =
        lib.mkEnableOption "enable thunderbolt + boltctl";
    };

    config = lib.mkIf config.mine.bolt.enable { 
      services.hardware.bolt.enable = true;
      environment.systemPackages = with pkgs; [ bolt ];
    };
}