{ lib, ... }:

{
  options.mine.ssh.enable =
    lib.mkEnableOption "enable and configure ssh, explicitly open 22/tcp";
}
