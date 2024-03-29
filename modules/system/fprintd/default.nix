{ lib, config, ... }: { 

    options = {
      mine.fprintd.enable =
        lib.mkEnableOption "enable fprintd";
    };

    config = lib.mkIf config.mine.fprintd.enable { 
      services.fprintd.enable = false; # causing nix build error 3/22/24
    };
}