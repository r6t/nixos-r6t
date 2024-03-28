{ pkgs, lib, config, ... }: { 

    options = {
      mine.fonts.enable =
        lib.mkEnableOption "enable my custom fonts";
    };

    config = lib.mkIf config.mine.fonts.enable { 
      fonts = {
        fontDir.enable = true;
        packages = with pkgs; [
          noto-fonts-emoji
          font-awesome
          hack-font
          nerdfonts
          source-sans-pro
        ];
      };
    };
}