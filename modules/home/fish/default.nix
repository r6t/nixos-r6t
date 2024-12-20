{ lib, config, pkgs, userConfig, ... }: { 

    options = {
      mine.home.fish.enable =
        lib.mkEnableOption "enable fish in home-manager";
    };

    config = lib.mkIf config.mine.home.fish.enable { 
      
      environment.systemPackages = with pkgs; [ 
        fishPlugins.fzf-fish
        fishPlugins.forgit
      ];
      programs.fish.enable = true;

      home-manager.users.${userConfig.username}.programs.fish = {
        enable = true;
        shellAliases = {
	  "nvf" = "nvim $(fzf -m --preview='bat --color=always {}')";
          "Git" = "git status";
          "Gd" = "git diff";
          "Gds" = "git diff --staged";
        };
      };
    };
}
