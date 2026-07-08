import ../../lib/mkFlatpakModule.nix {
  name = "libreoffice";
  configModule = import ./config.nix;
}
