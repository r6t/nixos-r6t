{ lib, ... }:

{
  options.mine.usb4-sfp.enable =
    lib.mkEnableOption "USB4 SFP+ 10G ixgbe adapter support";
}
