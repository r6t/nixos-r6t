import ../../lib/mkFlatpakModule.nix {
  name = "inkscape";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
