{ lib, ... }:

{
  options.mine.thunderbay.enable =
    lib.mkEnableOption "Unlock and mount drives in thunderbay box";
}
