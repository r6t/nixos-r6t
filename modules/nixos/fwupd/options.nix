{ lib, ... }:

{
  options.mine.fwupd.enable =
    lib.mkEnableOption "enable fwupd";
}
