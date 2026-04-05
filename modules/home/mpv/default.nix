import ../../lib/mkHomePackageModule.nix {
  name = "mpv";
  packages = p: [ p.mpv-unwrapped ];
}
