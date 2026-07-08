{ lib, config, ... }:
{

  options = {
    mine.flatpak.base.enable =
      lib.mkEnableOption "enable base flatpak configuration";
  };

  config = lib.mkIf config.mine.flatpak.base.enable (import ./config.nix);
}
