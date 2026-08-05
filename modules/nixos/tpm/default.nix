{ lib, config, pkgs, ... }: {

  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.tpm.enable (import ./config.nix { inherit pkgs; });
}
