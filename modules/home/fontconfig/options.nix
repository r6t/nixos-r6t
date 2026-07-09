{ lib, ... }:

{
  options.mine.home.fontconfig.enable =
    lib.mkEnableOption "enable fontconfig in home-manager";
}
