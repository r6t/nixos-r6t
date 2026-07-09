{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.docker.enable (import ./config.nix { inherit pkgs; });
}
