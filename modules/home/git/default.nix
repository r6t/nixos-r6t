{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.git.enable =
      lib.mkEnableOption "enable git in home-manager";
  };

  config = lib.mkIf config.mine.home.git.enable {
    home-manager.users.${userConfig.username} = {
      home = {
        packages = with pkgs; [
          pre-commit
          gh
          glab
        ];
      };
      programs.git = {
        enable = true;
        settings = {
          user = {
            name = "r6t";
            email = "git@r6t.io";
          };
          core = {
            editor = "nvim";
            init = { defaultBranch = "main"; };
            pull = { rebase = false; };
          };
          pull.ff = "only";
          credential = {
            helper = "!aws codecommit credential-helper $@";
            UseHttpPath = true;
          };
        };
        ignores = [
          ".DS_Store"
          "*.pyc"
        ];
      };
    };
  };
}
