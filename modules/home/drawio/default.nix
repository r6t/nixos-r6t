import ../../lib/mkHomePackageModule.nix {
  name = "drawio";
  configModule = import ./config.nix;
}
