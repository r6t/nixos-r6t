{ lib, config, pkgs, userConfig, ... }: { 

    options = {
      mine.home.mpv.enable =
        lib.mkEnableOption "enable mpv in home-manager";
    };

    config = lib.mkIf config.mine.home.mpv.enable { 
      home-manager.users.${userConfig.username}.home.packages = with pkgs; [ mpv-unwrapped ];
    };
}
