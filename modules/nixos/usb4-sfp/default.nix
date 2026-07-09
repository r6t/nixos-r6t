{ lib, config, pkgs, ... }:

{
  imports = [ ./options.nix ];

  config = lib.mkIf config.mine.usb4-sfp.enable (import ./config.nix { inherit pkgs; });
}
