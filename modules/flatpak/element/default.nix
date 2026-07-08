import ../../lib/mkFlatpakModule.nix {
  name = "element";
  configModule = import ./config.nix;
}
