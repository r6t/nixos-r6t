import ../../lib/mkHomePackageModule.nix {
  name = "yt-dlp";
  packages = p: [ p.yt-dlp ];
}
