import ../../lib/mkHomePackageModule.nix {
  name = "teams-for-linux";
  configModule = import ./config.nix;
}
