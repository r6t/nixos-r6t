{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.alloy.enable (import ./config.nix { inherit lib config; });
}
