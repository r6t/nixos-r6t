{ lib, ... }:

{
  options.mine.prometheus-node-exporter.enable =
    lib.mkEnableOption "enable prometheus-node-exporter";
}
