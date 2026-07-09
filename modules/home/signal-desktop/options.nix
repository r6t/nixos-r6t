{ lib, ... }:

{
  options.mine.home.signal-desktop.enable = lib.mkEnableOption "enable signal-desktop in home-manager";
}
