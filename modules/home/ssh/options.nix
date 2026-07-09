{ lib, ... }:

{
  options.mine.home.ssh.enable =
    lib.mkEnableOption "configure ssh in home-manager";
}
