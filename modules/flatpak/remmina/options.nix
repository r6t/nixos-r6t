{ lib, ... }:

{
  options.mine.flatpak.remmina.enable = lib.mkEnableOption "enable remmina via flatpak";
}
