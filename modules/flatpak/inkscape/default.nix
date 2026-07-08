import ../../lib/mkFlatpakModule.nix {
  name = "inkscape";
  configModule = import ./config.nix;
}
