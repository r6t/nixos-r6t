{ lib, config, ... }: {

  options = {
    mine.adb.enable =
      lib.mkEnableOption "enable adb";
  };

  config = lib.mkIf config.mine.adb.enable {
    programs.adb.enable = true;
  };
}
