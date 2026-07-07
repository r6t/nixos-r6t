{ lib, config, ... }:

{

  options = {
    mine.fwupd.enable =
      lib.mkEnableOption "enable fwupd";
  };

  config = lib.mkIf config.mine.fwupd.enable (import ./config.nix);
}
