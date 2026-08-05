{ lib, ... }:

{
  options.mine.flatpak.proton-mail.enable = lib.mkEnableOption "enable proton-mail via flatpak";
}
