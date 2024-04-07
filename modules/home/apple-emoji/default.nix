{ lib, config, pkgs, ... }:

let
  appleEmojiFont = pkgs.stdenv.mkDerivation rec {
    pname = "apple-emoji-linux";
    version = "16.4-patch.1";
    src = pkgs.fetchurl {
      url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/v${version}/AppleColorEmoji.ttf";
      sha256 = "15assqyxax63hah0g51jd4d4za0kjyap9m2cgd1dim05pk7mgvfm";
    };

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/share/fonts/apple-emoji
      cp ${src} $out/share/fonts/apple-emoji/AppleColorEmoji.ttf
    '';

    meta = {
      homepage = "https://github.com/samuelngs/apple-emoji-linux";
      description = "Apple Color Emoji font";
      license = pkgs.lib.licenses.unfree;
    };
  };
in

{ 

    options = {
      mine.home.apple-emoji.enable =
        lib.mkEnableOption "enable apple-emoji font in home-manager";
    };

    config = lib.mkIf config.mine.home.apple-emoji.enable { 
      nixpkgs = {
        overlays = [
        ];
        config = {
          allowUnfree = true;
          # Workaround for https://github.com/nix-community/home-manager/issues/2942
          allowUnfreePredicate = _: true;
        };
      };

      home-manager.users.r6t.home.packages = with pkgs; [ appleEmojiFont ];
    };
}