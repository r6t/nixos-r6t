{ lib, ... }:

{
  options.mine.apache.enable =
    lib.mkEnableOption "enable apache";
}
