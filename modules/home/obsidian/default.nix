{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.obsidian.enable =
        lib.mkEnableOption "enable obsidian in home-manager";
    };

    config = lib.mkIf config.mine.home.obsidian.enable { 
      nixpkgs = {
        overlays = [
        ];
        config = {
          allowUnfree = true;
          # Workaround for https://github.com/nix-community/home-manager/issues/2942
          allowUnfreePredicate = _: true;
        };
      };

      home-manager.users.r6t.home.packages = with pkgs; [ obsidian ];
    };
}