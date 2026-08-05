{ lib, ... }:

{
  options.mine.home.obs-studio.enable =
    lib.mkEnableOption "enable obs-studio in home-manager";
}
