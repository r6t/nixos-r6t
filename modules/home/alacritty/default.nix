{ lib, config, ... }: { 

    options = {
      mine.home.alacritty.enable =
        lib.mkEnableOption "enable alacritty in home-manager";
    };

    config = lib.mkIf config.mine.home.alacritty.enable { 
      programs.alacritty = {
        enable = true;
        settings = {
        font = {
          size = 14.0;
        };
        selection = {
          save_to_clipboard = true;
        };
        };
      };
    };
}