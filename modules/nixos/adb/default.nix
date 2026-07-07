{ lib, config, ... }: {

  options = {
    mine.adb.enable =
      lib.mkEnableOption "enable adb";
  };

  config = lib.mkIf config.mine.adb.enable (import ./config.nix);
}
