{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.calibre.enable =
        lib.mkEnableOption "enable calibre in home-manager";
    };

    config = lib.mkIf config.mine.home.calibre.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ calibre ];
    };
}