{ lib, ... }:

{
  options.mine.home.virt-viewer.enable = lib.mkEnableOption "enable virt-viewer in home-manager";
}
