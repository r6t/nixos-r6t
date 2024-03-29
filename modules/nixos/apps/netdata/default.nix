{ lib, config, ... }: { 

    options = {
      mine.netdata.enable =
        lib.mkEnableOption "enable and configure netdata";
    };

    config = lib.mkIf config.mine.netdata.enable { 
      services.netdata = {
        enable = true;
        user = "r6t";
        group = "users";
      };
    };
}