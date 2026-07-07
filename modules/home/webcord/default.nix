import ../../lib/mkHomePackageModule.nix {
  name = "webcord";
  configModule = import ./config.nix;
}
