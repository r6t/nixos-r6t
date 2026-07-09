{ lib, ... }:

{
  options.mine.home.atuin.enable =
    lib.mkEnableOption "enable atuin in home-manager";
}
