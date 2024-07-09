{ lib, config, ... }: { 

    options = {
      mine.flatpak.enable =
        lib.mkEnableOption "user level flatpak config";
    };

    config = lib.mkIf config.mine.home.flatpak.enable { 
      home-manager.users.r6t = { 
        home = {
          file.".profile".source = dotfiles/.profile;
        };
      };
    };
}