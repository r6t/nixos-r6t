{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.fzf.enable (import ./config.nix { inherit pkgs; });
}
