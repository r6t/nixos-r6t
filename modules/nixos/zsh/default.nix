{ lib, config, ... }: {

  options = {
    mine.zsh.enable =
      lib.mkEnableOption "enable and configure zsh";
  };

  config = lib.mkIf config.mine.zsh.enable {
    programs.zsh.enable = true;
  };
}
