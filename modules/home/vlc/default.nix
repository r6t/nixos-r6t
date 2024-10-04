{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.vlc.enable =
        lib.mkEnableOption "enable vlc in home-manager";
    };

    config = lib.mkIf config.mine.home.vlc.enable { 
      nixpkgs = {
        overlays = [
        ];
        config = {
          allowUnfree = true;
          # Workaround for https://github.com/nix-community/home-manager/issues/2942
          allowUnfreePredicate = _: true;
        };
      };

      home-manager.users.r6t.home.packages = with pkgs; [ 
        vlc
	ffmpeg-full
      ];
    };
}
