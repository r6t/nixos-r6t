{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.bolt.enable (import ./config.nix { inherit pkgs; });
}
