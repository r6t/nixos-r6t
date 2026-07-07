import ../../lib/mkHomePackageModule.nix {
  name = "bitwarden";
  configModule = import ./config.nix;
}
