{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.open-webui.enable (
    import ./config.nix { inherit lib config; }
  );
}
