{ lib, config, ... }:

{

  options = {
    mine.bootloader.enable =
      lib.mkEnableOption "configure bootloader";
  };

  config = lib.mkIf config.mine.bootloader.enable (import ./config.nix { inherit lib; });
}
