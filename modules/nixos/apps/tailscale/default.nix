{ lib, config, ... }: { 

    options = {
      mine.tailscale.enable =
        lib.mkEnableOption "enable and configure tailscale";
    };

    config = lib.mkIf config.mine.tailscale.enable { 
      services.tailscale.enable = true;
    };
}