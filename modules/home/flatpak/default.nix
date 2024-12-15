{ lib, config, nix-flatpak, ... }: { 

    options = {
      mine.flatpak.enable =
        lib.mkEnableOption "user level flatpak config";
    };

    config = lib.mkIf config.mine.home.flatpak.enable { 
      home-manager.users.r6t = { 
        imports = [ nix-flatpak.homeManagerModules.nix-flatpak ];
        home = {
          file.".profile".source = dotfiles/.profile;
        };
        sessionVariables = {
	  GDK_SCALE= "2";
          MOZ_ENABLE_WAYLAND = 1;
        };
        services.flatpak.packages = [ "com.github.iwalton3.jellyfin-media-player" ];

      };
    };
}
