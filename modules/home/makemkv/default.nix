{ lib, config, pkgs, userConfig, ... }:
{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.home.makemkv.enable (import ./config.nix {
    inherit pkgs userConfig;
  });
}
