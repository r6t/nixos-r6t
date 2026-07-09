{ lib, ... }:

{
  options.mine.home.teams-for-linux.enable = lib.mkEnableOption "enable teams-for-linux in home-manager";
}
