{ lib, ... }:

{
  options.mine.bolt.enable =
    lib.mkEnableOption "enable thunderbolt + boltctl";
}
