{ lib, ... }:

{
  options.mine.home.zellij.enable =
    lib.mkEnableOption "enable zellij in home-manager";
}
