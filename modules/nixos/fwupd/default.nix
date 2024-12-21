{ lib, config, ... }: {

  options = {
    mine.fwupd.enable =
      lib.mkEnableOption "enable fwupd";
  };

  config = lib.mkIf config.mine.fwupd.enable {
    services.fwupd.enable = true; # Linux firmware updater
  };
}
