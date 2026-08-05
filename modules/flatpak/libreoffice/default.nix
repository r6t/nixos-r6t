import ../../lib/mkFlatpakModule.nix {
  name = "libreoffice";
  optionsModule = ./options.nix;
  configModule = import ./config.nix;
}
