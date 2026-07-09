{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.ddc-i2c.enable (import ./config.nix { inherit config pkgs; });
}
