{ lib, config, ... }: {

  options = {
    mine.home.zellij.enable =
      lib.mkEnableOption "enable zellij in home-manager";
  };

  config = lib.mkIf config.mine.home.zellij.enable {
    home-manager.users.r6t.programs.zellij = {
      enable = true;
      enableZshIntegration = true;
    };
  };
}

