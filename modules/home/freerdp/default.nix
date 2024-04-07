{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.freerdp.enable =
        lib.mkEnableOption "enable freerdp in home-manager";
    };

    config = lib.mkIf config.mine.home.freerdp.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ freerdp ];
    };
}