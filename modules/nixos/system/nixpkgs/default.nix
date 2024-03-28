{ lib, config, ... }: { 

    options = {
      mine.nixpkgs.enable =
        lib.mkEnableOption "enable my nixpkgs defaults";
    };

    config = lib.mkIf config.mine.nixpkgs.enable { 
      nixpkgs = {
        overlays = [
        ];
        config = {
          allowUnfree = true;
        };
      };
    };
}