{ lib, ... }:

{
  options.mine.flatpak.libreoffice.enable = lib.mkEnableOption "enable libreoffice via flatpak";
}
