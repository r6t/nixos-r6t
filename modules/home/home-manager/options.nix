{ lib, ... }:

{
  options.mine.home.home-manager.enable =
    lib.mkEnableOption "enable home-manager core config";
}
