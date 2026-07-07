{ lib, config, ... }:

{

  options = {
    mine.sound.enable =
      lib.mkEnableOption "enable my audio";
  };

  config = lib.mkIf config.mine.sound.enable (import ./config.nix);
}
