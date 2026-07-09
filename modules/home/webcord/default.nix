import ../../lib/mkHomePackageModule.nix {
  name = "webcord";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
