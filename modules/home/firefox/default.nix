{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.firefox.enable =
        lib.mkEnableOption "enable firefox in home-manager";
    };

    config = lib.mkIf config.mine.home.firefox.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ firefox-wayland ];
    };
}