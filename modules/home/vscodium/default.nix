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
          bbenoist.nix
          continue.continue
          ms-python.python
          ms-python.isort
          pylyzer.pylyzer
          mkhl.direnv
          # redhat.vscode-yaml
          vscodevim.vim
          yzhang.markdown-all-in-one
        ];
        userSettings = {
          "editor.fontFamily" = "Hack Nerd Font, Noto Color Emoji";
          "editor.fontSize" = 14;
          "window.titleBarStyle" = "custom";
          "merge-conflict.autoNavigateNextConflict.enabled" = true;
          "redhat.telemetry.enabled" = false;
        };
      };
    };
  };
}
