{ lib, ... }:

{
  options.mine.flatpak.anki.enable = lib.mkEnableOption "enable anki via flatpak";
}
