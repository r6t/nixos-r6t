{ lib, ... }:

{
  options.mine.bootloader.enable =
    lib.mkEnableOption "configure bootloader";
}
