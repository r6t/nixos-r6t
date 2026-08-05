import ../../lib/mkHomePackageModule.nix {
  name = "freecad";
  configModule = import ./config.nix;
}
