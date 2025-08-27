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

      secrets = {
        "firefox_sync" = { owner = config.users.users.${userConfig.username}.name; };
        "openai/platform_key" = { owner = config.users.users.${userConfig.username}.name; };
        "caddy/headscale/aws_region" = { owner = config.users.users.${userConfig.username}.name; };
        "caddy/headscale/aws_access_key_id" = { owner = config.users.users.${userConfig.username}.name; };
        "caddy/headscale/aws_secret_access_key" = { owner = config.users.users.${userConfig.username}.name; };
        "caddy/lab/aws_region" = { owner = config.users.users.${userConfig.username}.name; };
        "caddy/lab/aws_access_key_id" = { owner = config.users.users.${userConfig.username}.name; };
        "caddy/lab/aws_secret_access_key" = { owner = config.users.users.${userConfig.username}.name; };
        "aws_acm/crown/caddy/aws_region" = { owner = config.users.users.${userConfig.username}.name; };
        "aws_acm/crown/caddy/aws_access_key_id" = { owner = config.users.users.${userConfig.username}.name; };
        "aws_acm/crown/caddy/aws_secret_access_key" = { owner = config.users.users.${userConfig.username}.name; };
        "pocket_id/admin_password" = { owner = config.users.users.${userConfig.username}.name; };
        "pocket_id/admin_user" = { owner = config.users.users.${userConfig.username}.name; };
        "pocket_id/https_endpoint" = { owner = config.users.users.${userConfig.username}.name; };
        "headscale/join_tailnet" = { owner = config.users.users.${userConfig.username}.name; };
        "grafana/oidc_client_id" = { owner = config.users.users.${userConfig.username}.name; };
        "grafana/oidc_client_secret" = { owner = config.users.users.${userConfig.username}.name; };
        "immich/db_password" = { owner = config.users.users.${userConfig.username}.name; };
        "immich/oidc_client_id" = { owner = config.users.users.${userConfig.username}.name; };
        "immich/oidc_client_secret" = { owner = config.users.users.${userConfig.username}.name; };
        "karakeep/oidc_client_id" = { owner = config.users.users.${userConfig.username}.name; };
        "karakeep/oidc_client_secret" = { owner = config.users.users.${userConfig.username}.name; };
        "karakeep/oidc_redirect_url" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/password" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/machine_id/mountainball" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/machine_id/silvertorch" = { owner = config.users.users.${userConfig.username}.name; };
        "syncthing/machine_id/saguaro" = { owner = config.users.users.${userConfig.username}.name; };
      };
    };
  };

}
