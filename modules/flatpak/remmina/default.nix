import ../../lib/mkFlatpakModule.nix {
  name = "remmina";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
