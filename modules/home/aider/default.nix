{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.aider.enable =
      lib.mkEnableOption "enable aider in home-manager";
  };

  config = lib.mkIf config.mine.home.aider.enable {
    home-manager.users.${userConfig.username}.home.packages = with pkgs; [ aider-chat-with-playwright ];
  };
}
