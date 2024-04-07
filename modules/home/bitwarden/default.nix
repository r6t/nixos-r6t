{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.bitwarden.enable =
        lib.mkEnableOption "enable bitwarden in home-manager";
    };

    config = lib.mkIf config.mine.home.bitwarden.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ bitwarden ];
    };
}