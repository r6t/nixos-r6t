import ../../lib/mkHomePackageModule.nix {
  name = "certbot";
  configModule = import ./config.nix;
}
