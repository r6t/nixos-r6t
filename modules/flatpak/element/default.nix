import ../../lib/mkFlatpakModule.nix {
  name = "element";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
