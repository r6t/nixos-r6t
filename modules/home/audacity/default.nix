{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.audacity.enable =
        lib.mkEnableOption "enable audacity in home-manager";
    };

    config = lib.mkIf config.mine.home.audacity.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ audacity ];
    };
}
