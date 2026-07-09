import ../../lib/mkHomePackageModule.nix {
  name = "orca-slicer";
  description = "enable orca-slicer 3D printing in home-manager";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
