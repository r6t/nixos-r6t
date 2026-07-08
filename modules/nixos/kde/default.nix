{ lib, config, pkgs, ... }:

{
  options = {
    mine.kde.enable =
      lib.mkEnableOption "enable and configure kde desktop";
    mine.kde.tablet =
      lib.mkEnableOption "tablet/touchscreen extras (on-screen keyboard packages)";
  };

  config = lib.mkIf config.mine.kde.enable
    (import ./config.nix {
      inherit lib config pkgs;
    }).config;
}
