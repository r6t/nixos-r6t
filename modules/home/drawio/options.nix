{ lib, ... }:

{
  options.mine.home.drawio.enable = lib.mkEnableOption "enable drawio in home-manager";
}
