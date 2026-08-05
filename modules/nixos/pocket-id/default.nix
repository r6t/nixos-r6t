{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.pocket-id.enable (
    import ./config.nix { inherit lib config; }
  );
}
