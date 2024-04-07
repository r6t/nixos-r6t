{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.mako.enable =
        lib.mkEnableOption "enable mako in home-manager";
    };

    config = lib.mkIf config.mine.home.mako.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ mako ];
    };
}