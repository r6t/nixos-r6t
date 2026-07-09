import ../../lib/mkFlatpakModule.nix {
  name = "zoom";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
