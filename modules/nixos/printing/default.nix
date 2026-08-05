{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.printing.enable (import ./config.nix { inherit pkgs; });
}
