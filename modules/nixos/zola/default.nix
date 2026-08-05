{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.zola.enable (import ./config.nix { inherit pkgs; });
}
