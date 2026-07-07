import ../../lib/mkHomePackageModule.nix {
  name = "protonmail-desktop";
  configModule = import ./config.nix;
}
