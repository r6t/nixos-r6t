{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.mako.enable =
        lib.mkEnableOption "enable mako in home-manager";
    };

    config = lib.mkIf config.mine.home.mako.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ 
        libnotify
        mako
      ];

      home-manager.users.r6t.services.mako = {
        enable = true;
        font = "Hack Nerd Font 12";
        icons = false;
        defaultTimeout = 2000;
      };

    };
}