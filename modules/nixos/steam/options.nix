{ lib, ... }:

{
  options.mine.steam = {
    enable = lib.mkEnableOption "enable nixos gaming with moonlight client and sandboxed steam";

    goldenballGameLauncher.enable = lib.mkEnableOption "goldenball-specific Steam game launcher profiles";
  };
}
