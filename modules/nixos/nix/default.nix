{ inputs, lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.nix.enable (import ./config.nix { inherit inputs lib config; });
}
