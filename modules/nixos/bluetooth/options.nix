{ lib, ... }:

{
  options.mine.bluetooth.enable =
    lib.mkEnableOption "enable my usual bluetooth config";
}
