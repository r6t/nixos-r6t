{ lib, ... }:

{
  options.mine.steam = {
    enable = lib.mkEnableOption "enable nixos gaming with moonlight client and sandboxed steam";

    profileLauncher.enable = lib.mkEnableOption "Steam game launcher profiles";
  };
}
