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
wrapHome {
  home.packages = gitPackages;
  home.file = allowedSignersFile;
  programs.git = gitConfig;
}
