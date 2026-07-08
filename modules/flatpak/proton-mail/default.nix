import ../../lib/mkFlatpakModule.nix {
  name = "proton-mail";
  configModule = import ./config.nix;
}
