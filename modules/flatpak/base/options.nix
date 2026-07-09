{ lib, ... }:

{
  options.mine.flatpak.base.enable =
    lib.mkEnableOption "enable base flatpak configuration";
}
