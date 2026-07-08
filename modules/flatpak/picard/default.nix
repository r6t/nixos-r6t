import ../../lib/mkFlatpakModule.nix {
  name = "picard";
  description = "enable musicbrainz picard via flatpak";
  configModule = import ./config.nix;
}
