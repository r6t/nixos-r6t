{ lib, config, pkgs, userConfig, ... }:

let
  svc = "incus";
  cfg = config.mine.${svc};
in
{
  options.mine.incus = {
    enable = lib.mkEnableOption "virtualization.incus module";
  };

  config = lib.mkIf cfg.enable {
    virtualisation = {
      ${svc} = {
        enable = true;
        agent.enable = false;
        ui.enable = true;
      };
      libvirtd.enable = true;
    };

    users.users.${userConfig.username} = {
      extraGroups = [ "incus-admin" ];
    };

    # set secrets
    sops.secrets = {
      "caddy/headscale/aws_access_key_id" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "caddy/headscale/aws_region" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "caddy/headscale/aws_secret_access_key" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "caddy/lab/aws_access_key_id" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "caddy/lab/aws_region" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "caddy/lab/aws_secret_access_key" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "grafana/oidc_client_id" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "grafana/oidc_client_secret" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "immich/db_password" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "immich/oidc_client_id" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
      "immich/oidc_client_secret" = lib.mkIf config.mine.sops.enable {
        owner = config.users.users.${userConfig.username}.name;
      };
    };
  };
}
