import ../../lib/mkFlatpakModule.nix {
  name = "remmina";
  configModule = import ./config.nix;
}
