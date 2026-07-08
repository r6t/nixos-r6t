{ lib, config, pkgs, userConfig, ... }:
{

  options = {
    mine.home.makemkv.enable =
      lib.mkEnableOption "enable makemkv";
  };

  config = lib.mkIf config.mine.home.makemkv.enable (import ./config.nix {
    inherit pkgs userConfig;
  });
}
