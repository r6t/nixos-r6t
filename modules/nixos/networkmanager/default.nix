{ lib, config, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.networkmanager.enable (import ./config.nix);
}
