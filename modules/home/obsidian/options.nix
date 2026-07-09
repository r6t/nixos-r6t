{ lib, ... }:

{
  options.mine.home.obsidian.enable =
    lib.mkEnableOption "enable obsidian in home-manager";
}
