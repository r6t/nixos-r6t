import ../../lib/mkFlatpakModule.nix {
  name = "picard";
  description = "enable musicbrainz picard via flatpak";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
