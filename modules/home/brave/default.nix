{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.brave.enable =
        lib.mkEnableOption "enable brave in home-manager";
    };

    config = lib.mkIf config.mine.home.brave.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ brave ];
    };
}