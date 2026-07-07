{ lib, config, pkgs, ... }:

{
  options = {
    mine.usb4-sfp.enable =
      lib.mkEnableOption "USB4 SFP+ 10G ixgbe adapter support";
  };

  config = lib.mkIf config.mine.usb4-sfp.enable (import ./config.nix { inherit pkgs; });
}
