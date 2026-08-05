{
  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };
  environment.sessionVariables = {
    DIRENV_LOG_FORMAT = "";
  };
}
