import ../../lib/mkHomePackageModule.nix {
  name = "freecad";
  packages = p: [ p.freecad ];
}
