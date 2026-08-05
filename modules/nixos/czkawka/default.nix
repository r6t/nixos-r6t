{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.czkawka.enable (import ./config.nix { inherit pkgs; });
}
