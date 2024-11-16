{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.protonmail-desktop.enable =
        lib.mkEnableOption "enable protonmail-desktop in home-manager";
    };

    config = lib.mkIf config.mine.home.protonmail-desktop.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ protonmail-desktop ];
    };
}
