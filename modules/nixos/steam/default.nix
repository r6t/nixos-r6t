{ lib, config, pkgs, userConfig, ... }:

{
  options.mine.steam = {
    enable = lib.mkEnableOption "enable nixos gaming with moonlight client and sandboxed steam";

    goldenballGameLauncher.enable = lib.mkEnableOption "goldenball-specific Steam game launcher profiles";
  };

  config = lib.mkIf config.mine.steam.enable
    (import ./config.nix {
      inherit lib config pkgs userConfig;
    }).config;
}
