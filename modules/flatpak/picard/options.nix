{ lib, ... }:

{
  options.mine.flatpak.picard.enable = lib.mkEnableOption "enable musicbrainz picard via flatpak";
}
