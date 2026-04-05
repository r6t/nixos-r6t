import ../../lib/mkHomePackageModule.nix {
  name = "k2pdfopt";
  description = "enable k2pdfopt pdf optimizer for kindle in home-manager";
  packages = p: [ p.k2pdfopt ];
}
