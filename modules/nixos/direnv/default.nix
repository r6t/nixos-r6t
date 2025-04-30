{ lib, config, ... }:

{
  options.mine.direnv.enable = lib.mkEnableOption "enable direnv configuration";

  config = lib.mkIf config.mine.direnv.enable {
    programs.direnv = {
      enable = true;
      enableFishIntegration = true;
      nix-direnv.enable = true;
    };
    environment.sessionVariables = {
      DIRENV_LOG_FORMAT = "";
    };
  };
}
