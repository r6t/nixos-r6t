{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.hyprpicker.enable =
        lib.mkEnableOption "enable hyprpicker in home-manager";
    };

    config = lib.mkIf config.mine.home.hyprpicker.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ hyprpicker ];
    };
}