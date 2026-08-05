{ lib, ... }:

{
  options.mine.fonts.enable =
    lib.mkEnableOption "enable my custom fonts";
}
