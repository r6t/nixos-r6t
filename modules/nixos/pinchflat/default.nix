{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.pinchflat.enable (import ./config.nix { inherit lib; });
}
