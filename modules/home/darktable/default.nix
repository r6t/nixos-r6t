{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.digikam.enable =
        lib.mkEnableOption "enable digikam in home-manager";
    };

    config = lib.mkIf config.mine.home.digikam.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ digikam ];
    };
}