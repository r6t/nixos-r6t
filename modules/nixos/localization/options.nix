{ lib, ... }:

{
  options.mine.localization.enable =
    lib.mkEnableOption "enable my localization defaults";
}
