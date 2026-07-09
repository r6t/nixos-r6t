{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.iperf.enable (import ./config.nix { inherit pkgs; });
}
