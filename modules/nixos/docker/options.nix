{ lib, ... }:

{
  options.mine.docker.enable =
    lib.mkEnableOption "enable standard docker: used inside LXC w no gpu or rootless";
}
