{ pkgs, lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.fonts.enable (import ./config.nix { inherit pkgs; });
}
