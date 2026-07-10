{ lib, ... }:

{
  options.mine.immich.enable = lib.mkEnableOption "enable immich server";
}
