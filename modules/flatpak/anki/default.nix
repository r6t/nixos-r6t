import ../../lib/mkFlatpakModule.nix {
  name = "anki";
  configModule = import ./config.nix;
}
