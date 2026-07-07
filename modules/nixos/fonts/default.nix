{ pkgs, lib, config, ... }:

{

  options = {
    mine.fonts.enable =
      lib.mkEnableOption "enable my custom fonts";
  };

  config = lib.mkIf config.mine.fonts.enable (import ./config.nix { inherit pkgs; });
}
