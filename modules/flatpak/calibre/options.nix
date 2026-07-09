{ lib, ... }:

{
  options.mine.flatpak.calibre.enable = lib.mkEnableOption "enable calibre via flatpak";
}
