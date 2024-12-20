{ lib, config, pkgs, userConfig, ... }: { 

    options = {
      mine.home.webcord.enable =
        lib.mkEnableOption "enable webcord in home-manager";
    };

    config = lib.mkIf config.mine.home.webcord.enable { 
      home-manager.users.${userConfig.username}.home.packages = with pkgs; [ webcord ];
    };
}
