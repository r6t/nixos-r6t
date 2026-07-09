{ lib, ... }:

{
  options.mine.home.fish.enable =
    lib.mkEnableOption "enable fish in home-manager";
}
