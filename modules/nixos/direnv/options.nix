{ lib, ... }:

{
  options.mine.direnv.enable = lib.mkEnableOption "enable direnv configuration";
}
