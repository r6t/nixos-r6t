{ pkgs, lib, config, userConfig, ... }: {

  options = {
    mine.sops = {
      enable =
        lib.mkEnableOption "gotta have my sops";
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
  };

  config = lib.mkIf config.mine.sops.enable {
    environment.systemPackages = with pkgs; [ age sops ];
    sops = {
      inherit (config.mine.sops) defaultSopsFile;
      defaultSopsFormat = "yaml";
      age.keyFile = config.mine.sops.ageKeyFile;
      validateSopsFiles = false;
    };
  };
}
