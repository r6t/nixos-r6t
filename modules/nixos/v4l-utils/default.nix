{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.v4l-utils.enable (import ./config.nix { inherit pkgs; });
}
