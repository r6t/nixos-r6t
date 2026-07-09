{ inputs, lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.user.enable (import ./config.nix { inherit inputs lib pkgs; });
}
