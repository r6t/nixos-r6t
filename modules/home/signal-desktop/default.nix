import ../../lib/mkHomePackageModule.nix {
  name = "signal-desktop";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
