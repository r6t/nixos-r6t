{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.bluetooth.enable (import ./config.nix);
}
