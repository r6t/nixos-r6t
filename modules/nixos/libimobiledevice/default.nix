{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.libimobiledevice.enable =
      lib.mkEnableOption "enable libimobiledevice iOS tools";
  };

  config = lib.mkIf config.mine.libimobiledevice.enable (import ./config.nix { inherit pkgs userConfig; });
}
