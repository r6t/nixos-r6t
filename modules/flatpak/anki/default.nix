import ../../lib/mkFlatpakModule.nix {
  name = "anki";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
