{ lib, config, pkgs, userConfig, ... }: { 

    options = {
      mine.home.bitwarden.enable =
        lib.mkEnableOption "enable bitwarden in home-manager";
    };

    config = lib.mkIf config.mine.home.bitwarden.enable { 
      home-manager.users.${userConfig.username}.home.packages = with pkgs; [ bitwarden ];
    };
}
