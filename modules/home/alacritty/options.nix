{ lib, ... }:

{
  options.mine.home.alacritty.enable =
    lib.mkEnableOption "enable alacritty in home-manager";
}
