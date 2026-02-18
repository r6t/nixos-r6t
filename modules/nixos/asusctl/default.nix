{ lib, config, pkgs, ... }: {

  options = {
    mine.asusctl.enable =
      lib.mkEnableOption "enable asusctl";
  };

  config = lib.mkIf config.mine.asusctl.enable {
    environment.systemPackages = with pkgs; [ asusctl ];
    services.asusd = {
      enable = true;
      enableUserService = true;
    };
    # The upstream service file has no [Install] section and relies on D-Bus
    # activation, but no D-Bus .service activation file is shipped. Force it
    # to start at boot.
    systemd.services.asusd.wantedBy = [ "multi-user.target" ];
  };
}
