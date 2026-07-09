import ../../lib/mkHomePackageModule.nix {
  name = "bitwarden";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
