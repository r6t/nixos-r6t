{ lib, config, ... }: { 

    options = {
      mine.fprintd.enable =
        lib.mkEnableOption "enable fprintd";
    };

    config = lib.mkIf config.mine.fprintd.enable { 
      services.fprintd.enable = true;
    };
}
