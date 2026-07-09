{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.direnv.enable (import ./config.nix);
}
