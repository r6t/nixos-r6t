{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.vscodium.enable =
        lib.mkEnableOption "enable vscodium in home-manager";
    };

    config = lib.mkIf config.mine.home.vscodium.enable { 
      nixpkgs = {
        overlays = [
        ];
        config = {
          allowUnfree = true;
          # Workaround for https://github.com/nix-community/home-manager/issues/2942
          allowUnfreePredicate = _: true;
        };
      };

      home-manager.users.r6t.programs.vscode = {
        enable = true;
        package = pkgs.vscodium;
        extensions = with pkgs.vscode-extensions; [
          bbenoist.nix
          continue.continue
          dracula-theme.theme-dracula
          ms-azuretools.vscode-docker
          ms-python.isort
          ms-python.python
          ms-python.vscode-pylance # unfree
          redhat.vscode-yaml
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
}