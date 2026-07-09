{ lib, ... }:

{
  options.mine.home.orca-slicer.enable = lib.mkEnableOption "enable orca-slicer 3D printing in home-manager";
}
