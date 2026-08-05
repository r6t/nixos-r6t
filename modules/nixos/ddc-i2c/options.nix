{ lib, ... }:

{
  options.mine.ddc-i2c.enable =
    lib.mkEnableOption "enable display control stuff";
}
