{ lib, config, pkgs, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.rdfind.enable (import ./config.nix { inherit pkgs; });
}
