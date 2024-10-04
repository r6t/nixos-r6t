{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.mpv.enable =
        lib.mkEnableOption "enable mpv in home-manager";
    };

      home-manager.users.r6t.home.packages = with pkgs; [ 
        mpv-unwrapped
      ];
    };
}
