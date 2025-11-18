{ lib, config, userConfig, ... }: {

  options = {
    mine.home.atuin.enable =
      lib.mkEnableOption "enable atuin in home-manager";
  };

  config = lib.mkIf config.mine.home.atuin.enable {
    home-manager.users.${userConfig.username}.programs.atuin = {
      enable = true;
      # causes bind -k warning on fish >4.1
      # atuin 18.8.0 + fish 4.1.2 still throwing -k warnings
      enableFishIntegration = true;
      flags = [ "--disable-up-arrow" ];

      # settings = {};

    };
  };
}
