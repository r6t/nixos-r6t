{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.prometheus-node-exporter.enable (import ./config.nix);
}
