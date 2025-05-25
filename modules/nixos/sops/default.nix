{ pkgs, lib, config, userConfig, ... }: {

  options = {
    mine.sops.enable =
      lib.mkEnableOption "set up my sops";
  };

  config = lib.mkIf config.mine.sops.enable {
    environment.systemPackages = with pkgs; [ age sops ];

    sops = {
      defaultSopsFile = "/home/${userConfig.username}/git/sops-ryan/secrets.yaml";
      defaultSopsFormat = "yaml";
      age.keyFile = "/home/${userConfig.username}/.config/sops/age/keys.txt";

      secrets = {
        "firefox_sync" = { owner = config.users.users.${userConfig.username}.name; };
        "openai/platform_key" = { owner = config.users.users.${userConfig.username}.name; };
        "karakeep/oidc_client_id" = { owner = config.users.users.${userConfig.username}.name; };
        "karakeep/oidc_client_secret" = { owner = config.users.users.${userConfig.username}.name; };
        "karakeep/oidc_redirect_url" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/password" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/machine_id/mailmac" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/machine_id/mountainball" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/machine_id/starfish" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/machine_id/silvertorch" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/machine_id/saguaro" = { owner = config.users.users.${userConfig.username}.name; };
      };

      validateSopsFiles = false;
    };
  };

}

