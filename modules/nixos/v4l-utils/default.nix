{ lib, config, pkgs, ... }: { 

    options = {
      mine.v4l-utils.enable =
        lib.mkEnableOption "enable v4l-utils for camlink support";
    };

    config = lib.mkIf config.mine.v4l-utils.enable { 
      environment.systemPackages = with pkgs; [
       v4l-utils
      ];
    };
}
