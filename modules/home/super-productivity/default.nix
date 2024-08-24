{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.super-productivity.enable =
        lib.mkEnableOption "super-productivity";
    };

    config = lib.mkIf config.mine.home.super-productivity.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ super-productivity ];
    };
}