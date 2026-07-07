{ lib, config, userConfig, ... }:
{

  options = {
    mine.home.crush.enable =
      lib.mkEnableOption "crush user config (pkg in devshell)";
  };
  config = lib.mkIf config.mine.home.crush.enable
    (import ./config.nix { inherit userConfig; });
}
