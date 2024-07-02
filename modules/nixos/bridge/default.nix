{ lib, config, pkgs, ... }: { 

    options = {
      mine.bridge.enable =
        lib.mkEnableOption "enable network bridge";
    };

    config = lib.mkIf config.mine.bridge.enable { 
      networking = {
        interfaces = {
          br0 = {
            useDHCP = true;
          };
        };
        bridges.br0.interfaces = [ "eno1" ];
      };
  };
}