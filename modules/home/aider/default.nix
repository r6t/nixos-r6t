{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.aider.enable =
      lib.mkEnableOption "enable aider in home-manager";
  };

  config = lib.mkIf config.mine.home.aider.enable {
    home-manager.users.${userConfig.username}.home = {
      packages = with pkgs; [ aider-chat-with-playwright ];
      file.".aider.conf.yml".source = ./aider.conf.yml;
      sessionVariables = {
        AIDER_AUTO_ACCEPT_ARCHITECT = "false";
        AIDER_EDIT_FORMAT = "diff";
        OLLAMA_API_BASE = "https://ollama.r6t.io";
      };
    };
  };
}
