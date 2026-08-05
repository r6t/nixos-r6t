import ../../lib/mkHomePackageModule.nix {
  name = "yt-dlp";
  configModule = import ./config.nix;
}
