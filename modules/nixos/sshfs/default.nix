{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.sshfs.enable (import ./config.nix { inherit pkgs; });
}
