import ../../lib/mkHomePackageModule.nix {
  name = "signal-desktop";
  packages = p: [ p.signal-desktop ];
}
