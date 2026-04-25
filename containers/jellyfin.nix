{ ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/jellyfin/default.nix
  ];

  networking.hostName = "jellyfin";

  mine.jellyfin.enable = true;

  # Let Nix own encoding.xml. The NixOS jellyfin module derives TranscodingTempPath
  # from cacheDir (/var/cache/jellyfin) on every restart, so the /cache and /config
  # path drift from the legacy Docker layout cannot return. No GPU in this LXC and
  # most playback is direct-play, so upstream transcoding defaults are fine.
  services.jellyfin.forceEncodingConfig = true;
}
