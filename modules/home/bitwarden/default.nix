import ../../lib/mkHomePackageModule.nix {
  name = "bitwarden";
  packages = p: [ p.bitwarden-desktop ];
}
