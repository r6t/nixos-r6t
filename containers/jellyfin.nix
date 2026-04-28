{ ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
    ../modules/nixos/jellyfin/default.nix
  ];

  networking.hostName = "jellyfin";

  mine.jellyfin.enable = true;

  # No GPU in this LXC; hardwareAcceleration stays off (upstream default).
  # Jellyfin creates encoding.xml from its own defaults on first run, which
  # correctly uses `cacheDir/transcodes` (i.e. /var/cache/jellyfin/transcodes).
  #
  # Note: services.jellyfin.forceEncodingConfig has no effect unless
  # hardwareAcceleration.enable = true — the upstream module gates the
  # preStart script behind HWAccel. If GPU ever gets added to this LXC,
  # set hardwareAcceleration.enable = true AND forceEncodingConfig = true
  # to put Nix in charge of encoding.xml.
}
