import ../../lib/mkHomePackageModule.nix {
  name = "virt-viewer";
  configModule = import ./config.nix;
}
