{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.darktable.enable =
        lib.mkEnableOption "enable darktable in home-manager";
    };

    config = lib.mkIf config.mine.home.darktable.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ darktable ];
    };
}