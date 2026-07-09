{ lib, ... }:

{
  options.mine.flatpak.inkscape.enable = lib.mkEnableOption "enable inkscape via flatpak";
}
