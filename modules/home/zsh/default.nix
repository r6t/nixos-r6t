{ lib, config, ... }: { 

    options = {
      mine.home.zsh.enable =
        lib.mkEnableOption "enable zsh in home-manager";
    };

    config = lib.mkIf config.mine.home.zsh.enable { 
      home-manager.users.r6t.programs.zsh = {
        enable = true;
        oh-my-zsh = {
          enable = true;
          plugins = [ "aws" "git" "python" ];
          theme = "xiong-chiamiov-plus";
        };
        shellAliases = {
				  "nvf" = "nvim $(fzf -m --preview='bat --color=always {}')";
          "gst" = "git status";
          "gd" = "git diff";
          "gds" = "git diff --staged";
        };
      };
    };
}
