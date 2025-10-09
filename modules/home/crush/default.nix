{ lib, config, userConfig, ... }:
let
  configFile = ./config.json;
in
{

  options = {
    mine.home.crush.enable =
      lib.mkEnableOption "crush user config (pkg in devshell)";
  };
  config = lib.mkIf config.mine.home.crush.enable {
    home-manager.users.${userConfig.username}.home.file.".config/crush/crush.json".source = configFile;
  };
}
