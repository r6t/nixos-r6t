{ lib, config, ... }:

{

  options = {
    mine.localization.enable =
      lib.mkEnableOption "enable my localization defaults";
  };

  config = lib.mkIf config.mine.localization.enable (import ./config.nix);
}
