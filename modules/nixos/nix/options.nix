{ lib, ... }:

{
  options.mine.nix.enable = lib.mkEnableOption "enable my usual nix config";
}
