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
        sessionVariables = {
	  GDK_SCALE= "2";
	  # GDK_DPI_SCALE = "0.5";
          MOZ_ENABLE_WAYLAND = 1;
        };

      };
    };
}
