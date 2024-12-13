{ lib, config, pkgs, ... }: { 

    options = {
      mine.rdfind.enable =
        lib.mkEnableOption "enable rdfind";
    };

    config = lib.mkIf config.mine.rdfind.enable { 
      environment.systemPackages = with pkgs; [ rdfind ];
    };
}
