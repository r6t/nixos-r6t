{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.webcord.enable =
        lib.mkEnableOption "enable webcord in home-manager";
    };

    config = lib.mkIf config.mine.home.webcord.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ webcord ];
    };
}