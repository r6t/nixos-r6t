{ lib, ... }:

{
  options.mine.iperf.enable =
    lib.mkEnableOption "enable iperf";
}
