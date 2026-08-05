{ lib, ... }:

{
  options.mine.flatpak.element.enable = lib.mkEnableOption "enable element via flatpak";
}
