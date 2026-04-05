import ../../lib/mkHomePackageModule.nix {
  name = "webcord";
  packages = p: [ p.webcord ];
}
