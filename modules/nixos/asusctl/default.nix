{ lib, config, pkgs, ... }: {

  options = {
    mine.asusctl.enable =
      lib.mkEnableOption "enable asusctl";
  };

  config = lib.mkIf config.mine.asusctl.enable {
    environment.systemPackages = with pkgs; [ asusctl ];
    services.asusd = {
      enable = true;
    };
    # The upstream service file has no [Install] section and relies on D-Bus
    # activation, but no D-Bus .service activation file is shipped. Force it
    # to start at boot.
    systemd.services.asusd.wantedBy = [ "multi-user.target" ];
    # asusd.service uses ProtectSystem=strict + ReadWritePaths=/etc/asusd/
    # Systemd namespace setup fails with status=226/NAMESPACE if /etc/asusd
    # doesn't exist yet. The NixOS upstream module only creates files under
    # /etc/asusd when config options (asusdConfig, profileConfig, etc.) are
    # set — with all defaults it creates nothing. Ensure the directory exists
    # before asusd starts so the sandbox can set up its bind-mount overlay.
    systemd.tmpfiles.rules = [ "d /etc/asusd 0755 root root -" ];
  };
}
