{ lib, config, ... }:

{

  options = {
    mine.prometheus-node-exporter.enable =
      lib.mkEnableOption "enable prometheus-node-exporter";
  };

  config = lib.mkIf config.mine.prometheus-node-exporter.enable (import ./config.nix);
}
