{ lib, ... }:

{
  options.mine.sshfs.enable =
    lib.mkEnableOption "enable and configure sshfs";
}
