{ lib, ... }:

{
  options.mine.npm.enable = lib.mkEnableOption "enable npm";
}
