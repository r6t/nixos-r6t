{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.sound.enable (import ./config.nix);
}
