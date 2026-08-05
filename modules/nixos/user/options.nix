{ lib, userConfig, ... }:

{
  options.mine.user = {
    enable = lib.mkEnableOption "enable the primary user account";

    name = lib.mkOption {
      type = lib.types.str;
      default = userConfig.username;
      description = "Primary local user name";
    };

    extraGroups = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "docker" "input" "incus" "networkmanager" "wheel" ];
      description = "Supplementary groups for the primary local user";
    };

    authorizedKeysFromGithub = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the flake ssh-keys input as authorized keys for the primary user";
    };

    authorizeRootKeys = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Install the flake ssh-keys input as root authorized keys";
    };
  };
}
