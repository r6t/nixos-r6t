{ lib, ... }:

{
  options.mine.networkmanager.enable =
    lib.mkEnableOption "enable networkmanager";
}
