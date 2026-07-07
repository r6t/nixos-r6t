import ../../lib/mkHomePackageModule.nix {
  name = "signal-desktop";
  configModule = import ./config.nix;
}
