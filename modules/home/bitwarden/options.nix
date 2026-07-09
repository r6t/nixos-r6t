{ lib, ... }:

{
  options.mine.home.bitwarden.enable = lib.mkEnableOption "enable bitwarden in home-manager";
}
