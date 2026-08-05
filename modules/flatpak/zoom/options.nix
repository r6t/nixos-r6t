{ lib, ... }:

{
  options.mine.flatpak.zoom.enable = lib.mkEnableOption "enable zoom via flatpak";
}
