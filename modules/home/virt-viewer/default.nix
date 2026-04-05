import ../../lib/mkHomePackageModule.nix {
  name = "virt-viewer";
  packages = p: [ p.virt-viewer ];
}
