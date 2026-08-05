{ pkgs, lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.sops.enable (import ./config.nix { inherit lib config pkgs; });
}
