{ lib, config, pkgs, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.apache.enable (import ./config.nix { inherit pkgs; });
}
