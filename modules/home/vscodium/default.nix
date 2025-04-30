{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.vscodium.enable =
      lib.mkEnableOption "enable vscodium in home-manager";
  };

  config = lib.mkIf config.mine.home.vscodium.enable {
    home-manager.users.${userConfig.username}.programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          continue.continue
          ms-python.python
          pylyzer.pylyzer
          mkhl.direnv
          vscodevim.vim
          yzhang.markdown-all-in-one
        ];
      };
    };
  };
}
