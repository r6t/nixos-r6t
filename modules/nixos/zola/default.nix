{ lib, config, pkgs, ... }: { 

    options = {
      mine.zola.enable =
        lib.mkEnableOption "enable zola static site generator";
    };

    config = lib.mkIf config.mine.zola.enable { 
      environment.systemPackages = with pkgs; [
       zola
      ];
    };
}
