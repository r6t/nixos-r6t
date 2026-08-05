{ lib, config, ... }:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.flatpak.base.enable (import ./config.nix);
}
