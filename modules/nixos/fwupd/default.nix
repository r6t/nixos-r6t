{ lib, config, ... }: {

  options = {
    mine.fwupd.enable =
      lib.mkEnableOption "enable fwupd";
  };

  config = lib.mkIf config.mine.fwupd.enable {
    services.fwupd.enable = true; # Linux firmware updater

    # nixos-rebuild may restart polkit during activation while fwupd-refresh is
    # also triggered; fwupdmgr then exits with "PolicyKit daemon is not
    # available". Ensure the refresh job waits for polkit instead of racing it.
    systemd.services.fwupd-refresh = {
      after = [ "polkit.service" ];
      wants = [ "polkit.service" ];
    };
  };
}
