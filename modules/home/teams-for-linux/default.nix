import ../../lib/mkHomePackageModule.nix {
  name = "teams-for-linux";
  packages = p: [ p.teams-for-linux ];
}
