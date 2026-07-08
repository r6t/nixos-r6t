import ../../lib/mkFlatpakModule.nix {
  name = "calibre";
  configModule = import ./config.nix;
}
