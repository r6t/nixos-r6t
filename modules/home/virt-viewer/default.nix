import ../../lib/mkHomePackageModule.nix {
  name = "virt-viewer";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
