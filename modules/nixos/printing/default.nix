{ lib, config, pkgs, ... }: {

  options = {
    mine.printing.enable =
      lib.mkEnableOption "enable printing with brlaser + discovery";
  };

  config = lib.mkIf config.mine.printing.enable {
    environment.systemPackages = with pkgs; [ cups-filters ];
    services = {
      avahi = {
        enable = true;
        # AirPrint support
        nssmdns4 = true;
      };
      printing = {
        drivers = [ pkgs.brlaser ];
        enable = true;
      };
    };
  };
}
