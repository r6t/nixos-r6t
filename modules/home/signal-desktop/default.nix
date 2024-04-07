{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.signal-desktop.enable =
        lib.mkEnableOption "enable signal-desktop in home-manager";
    };

    config = lib.mkIf config.mine.home.signal-desktop.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ signal-desktop ];
    };
}