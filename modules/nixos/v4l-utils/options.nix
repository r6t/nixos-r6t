{ lib, ... }:

{
  options.mine.v4l-utils.enable =
    lib.mkEnableOption "enable v4l-utils for camlink support";
}
