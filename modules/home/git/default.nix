{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.git;
  wrapHome = import ../../lib/mkPortableHomeConfig.nix { inherit isNixOS userConfig; };

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
      gpg.ssh.allowedSignersFile = "~/.ssh/allowed_signers";
      tag.gpgSign = true;
    };
    signing = {
      format = "ssh";
      key = cfg.signingKey;
      signByDefault = true;
    };
    ignores = [
      ".DS_Store"
      "*.pyc"
    ];
  };

  # allowed_signers file for local signature verification (git log --show-signature)
  allowedSignersFile = lib.mkIf (cfg.signingPubKey != null) {
    ".ssh/allowed_signers".text = "${cfg.userEmail} ${cfg.signingPubKey}";
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

    signingKey = lib.mkOption {
      type = lib.types.str;
      description = "Path to SSH public key used for commit signing (git finds the private key automatically)";
      default = "~/.ssh/id_ed25519.pub";
    };

    signingPubKey = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      description = "SSH public key string for allowed_signers (enables local signature verification)";
      default = null;
      example = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAA...";
    };
  };

  config = lib.mkIf cfg.enable (wrapHome {
    home.packages = gitPackages;
    home.file = allowedSignersFile;
    programs.git = gitConfig;
  });
}
