{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.zola.enable =
        lib.mkEnableOption "enable zola static site generator";
    };

    config = lib.mkIf config.mine.home.zola.enable { 
      home-manager.users.r6t.home.packages = with pkgs; [ zola ];
    };
}
