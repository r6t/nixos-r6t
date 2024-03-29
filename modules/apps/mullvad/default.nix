{ lib, config, ... }: { 

    options = {
      mine.mullvad.enable =
        lib.mkEnableOption "enable mullvad desktop app";
    };

    config = lib.mkIf config.mine.mullvad.enable { 
      services.mullvad-vpn.enable = true; # Mullvad desktop app
    };
}