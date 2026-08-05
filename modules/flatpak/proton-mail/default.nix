import ../../lib/mkFlatpakModule.nix {
  name = "proton-mail";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
