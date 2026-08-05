import ../../lib/mkHomePackageModule.nix {
  name = "mpv";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
