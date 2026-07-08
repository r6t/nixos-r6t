import ../../lib/mkFlatpakModule.nix {
  name = "zoom";
  configModule = import ./config.nix;
}
