{ lib, userConfig, ... }:

{
  options.mine.sops = {
    enable = lib.mkEnableOption "SOPS configuration through the legacy compatibility wrapper";

    available = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether this host has sops-nix configured and can declare optional secrets.

        This is a semantic availability flag for modules that add sops.secrets
        conditionally. It is not the activation mechanism for the SOPS profile.
      '';
    };

    defaultSopsFile = lib.mkOption {
      type = lib.types.str;
      default = "/home/${userConfig.username}/git/sops-ryan/secrets.yaml";
      description = "Path to the default SOPS file";
    };

    ageKeyFile = lib.mkOption {
      type = lib.types.str;
      default = "/home/${userConfig.username}/.config/sops/age/keys.txt";
      description = "Path to the age key file";
    };
  };
}
