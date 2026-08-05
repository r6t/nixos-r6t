{ pkgs, ... }:

{
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
}
