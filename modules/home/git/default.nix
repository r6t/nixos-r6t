{ lib, config, ... }: { 

    options = {
      mine.home.git.enable =
        lib.mkEnableOption "enable git in home-manager";
    };

    config = lib.mkIf config.mine.home.git.enable { 
      home-manager.users.r6t.programs.git = {
        enable = true;
        userName = "r6t";
        userEmail = "git@r6t.io";
        extraConfig = {
          core = {
            editor = "nvim";
            init = { defaultBranch = "main"; };
            pull = { rebase = false; };
          };
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
}
