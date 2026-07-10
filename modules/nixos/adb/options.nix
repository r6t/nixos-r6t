{ lib, ... }:

{
  options.mine.adb.enable =
    lib.mkEnableOption "enable adb";
}
