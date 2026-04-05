import ../../lib/mkHomePackageModule.nix {
  name = "orca-slicer";
  description = "enable orca-slicer 3D printing in home-manager";
  packages = p: [ p.orca-slicer ];
}
