{ lib, config, ... }: { 

    options = {
      mine.printing.enable =
        lib.mkEnableOption "enable printing";
    };

    config = lib.mkIf config.mine.printing.enable { 
      services.printing.enable = true;
    };
}