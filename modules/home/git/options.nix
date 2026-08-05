{ lib, ... }:

{
  options.mine.home.git = {
    enable = lib.mkEnableOption "enable git in home-manager";

    userName = lib.mkOption {
      type = lib.types.str;
      description = "Git user.name value";
      default = "User";
    };

    userEmail = lib.mkOption {
      type = lib.types.str;
      description = "Git user.email value";
      default = "user@example.com";
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
}
