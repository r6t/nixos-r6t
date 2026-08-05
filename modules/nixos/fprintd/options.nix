{ lib, ... }:

{
  options.mine.fprintd.enable =
    lib.mkEnableOption "enable fprintd";
}
