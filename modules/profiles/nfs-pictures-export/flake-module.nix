{
  flake.modules.nixos.nfs-pictures-export = { lib, ... }: {
    mine.nfs.exports.Pictures = {
      sourcePath = lib.mkDefault "/mnt/thunderbay/8TB-C/Pictures";
      includePaths = lib.mkDefault [
        "cameras"
        "meme"
        "reference"
        "Screenshots"
        "wallpaper"
        "wallpaper-vertical"
      ];
      fsid = lib.mkDefault 0;
      mountPointGuard = lib.mkDefault "/mnt/thunderbay/8TB-C";
      after = lib.mkDefault [ "mnt-thunderbay-8TB\\x2dC.mount" ];
      requires = lib.mkDefault [ "mnt-thunderbay-8TB\\x2dC.mount" ];
    };
  };
}
