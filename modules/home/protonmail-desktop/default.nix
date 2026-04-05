import ../../lib/mkHomePackageModule.nix {
  name = "protonmail-desktop";
  packages = p: [ p.protonmail-desktop ];
}
