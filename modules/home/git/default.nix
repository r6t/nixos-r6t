{ lib, config, pkgs, userConfig ? null, ... }:

let
  cfg = config.mine.home.git;
  isNixOS = userConfig != null;

  # Shared packages
  gitPackages = with pkgs; [
    pre-commit
    gh
    glab
  ];

  # Shared git configuration
  gitConfig = {
    enable = true;
    settings = {
      user = {
        name = cfg.userName;
        email = cfg.userEmail;
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

in
{
  options.mine.home.git = {
    enable = lib.mkEnableOption "enable git in home-manager";

    userName = lib.mkOption {
      type = lib.types.str;
      description = "Git user.name value";
      default = "r6t";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Git user.email value";
      default = "git@r6t.io";
    };
  };

  config = lib.mkIf cfg.enable (
    if isNixOS then {
      # NixOS mode: configure via home-manager.users wrapper
      home-manager.users.${userConfig.username} = {
        home.packages = gitPackages;
        programs.git = gitConfig;
      };
    } else {
      # Standalone home-manager mode: configure directly
      home.packages = gitPackages;
      programs.git = gitConfig;
    }
  );
}
