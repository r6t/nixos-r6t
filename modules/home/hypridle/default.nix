{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.hypridle.enable =
        lib.mkEnableOption "enable hypridle in home-manager";
    };

    config = lib.mkIf config.mine.home.hypridle.enable { 
      home-manager.users.r6t.home = {
        packages = with pkgs; [ hypridle ];
        file.".config/hypr/hypridle.conf".source = ../../../dotfiles/hypr/hypridle.conf;
      };
    };
}