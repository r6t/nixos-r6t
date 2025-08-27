{ pkgs, lib, config, userConfig, ... }: {

  options = {
    mine.sops.enable =
      lib.mkEnableOption "gotta have my sops";
  };

  config = lib.mkIf config.mine.sops.enable {
    environment.systemPackages = with pkgs; [ age sops ];
    sops = {
      defaultSopsFile = "/home/${userConfig.username}/git/sops-ryan/secrets.yaml";
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/${userConfig.username}/.config/sops/age/keys.txt";
      validateSopsFiles = false;
    };
  };
}
