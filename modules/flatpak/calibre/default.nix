import ../../lib/mkFlatpakModule.nix {
  name = "calibre";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
