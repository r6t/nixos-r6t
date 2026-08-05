import ../../lib/mkHomePackageModule.nix {
  name = "drawio";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
