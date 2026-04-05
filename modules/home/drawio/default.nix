import ../../lib/mkHomePackageModule.nix {
  name = "drawio";
  packages = p: [ p.drawio ];
}
