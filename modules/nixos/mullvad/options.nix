{ lib, ... }:

{
  options.mine.mullvad.enable =
    lib.mkEnableOption "enable mullvad desktop app";
}
