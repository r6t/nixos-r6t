import ../../lib/mkHomePackageModule.nix {
  name = "mpv";
  configModule = import ./config.nix;
}
