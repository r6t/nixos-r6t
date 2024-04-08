{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.hyprlock.enable =
        lib.mkEnableOption "enable hyprlock in home-manager";
    };

    config = lib.mkIf config.mine.home.hyprlock.enable { 
      home-manager.users.r6t.home = {
        packages = with pkgs; [ hyprlock ];
        file.".config/hypr/hyprlock.conf".source = dotfiles/hyprlock.conf;
      };
    };
}