{ lib, ... }:

{
  options.mine.home.browsers.enable =
    lib.mkEnableOption "enable desktop web browsers in home-manager";
}
