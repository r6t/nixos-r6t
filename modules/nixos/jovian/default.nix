{ inputs, jovian, lib, config, pkgs, ... }: { 

    imports = [
      inputs.jovian.nixosModules.default
    ];
  
    options = {
      mine.jovian.enable =
        lib.mkEnableOption "configure jovian-nixos on steam deck";
    };

    config = lib.mkIf config.mine.jovian.enable { 
      jovian = {
        devices.steamdeck.enable = true;
        steam = {
          enable = true;
          autoStart = true;
          user = "r6t";
          desktopSession = "kde";
        };
      };

      services.xserver = {
          enable = true;
          xkb = {
            variant = "";
            layout = "us";
          };
      };

      hardware.pulseaudio.enable = false;
    };
}