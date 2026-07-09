import ../../lib/mkHomePackageModule.nix {
  name = "teams-for-linux";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
