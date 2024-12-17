{ lib, config, ... }: { 

    options = {
      mine.flatpak.jellyfin-player.enable =
        lib.mkEnableOption "enable jellyfin media player via flatpak";
    };

    config = lib.mkIf config.mine.flatpak.jellyfin-player.enable { 
      services.flatpak.packages = [
        { appId = "com.github.iwalton3.jellyfin-media-player"; origin = "flathub";  }
      ];
    };
}
