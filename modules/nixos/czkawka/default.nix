{ lib, config, pkgs, ... }: { 

    options = {
      mine.czkawka.enable =
        lib.mkEnableOption "enable czkawka";
    };

    config = lib.mkIf config.mine.czkawka.enable { 
      environment.systemPackages = with pkgs; [ czkawka ];
    };
}
