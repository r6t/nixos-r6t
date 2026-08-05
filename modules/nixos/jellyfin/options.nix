{ lib, ... }:

{
  options.mine.jellyfin.enable = lib.mkEnableOption "jellyfin server module";
}
