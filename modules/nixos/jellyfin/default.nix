{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.jellyfin.enable (
    import ./config.nix { inherit pkgs; }
  );
}
