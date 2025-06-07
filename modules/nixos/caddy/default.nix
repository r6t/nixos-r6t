{ config, lib, pkgs, ... }:

let
  caddyfile = builtins.readFile ./Caddyfile;
  envFile = "/etc/caddy/env";
in
{
  options.mine.caddy.enable = lib.mkEnableOption "Enable Caddy with Route53 DNS";

  config = lib.mkIf config.mine.caddy.enable {
    # Write the Caddyfile
    environment.etc."caddy/Caddyfile".text = caddyfile;

    # Securely render environment variables from secrets
    systemd.services = {
      caddy = {
        wants = [ "write-caddy-env.service" ];
        after = [ "write-caddy-env.service" ];
        serviceConfig = {
          EnvironmentFile = envFile;
          AmbientCapabilities = [ "CAP_NET_BIND_SERVICE" ];
          CapabilityBoundingSet = [ "CAP_NET_BIND_SERVICE" ];
          NoNewPrivileges = true;
          ProtectSystem = "full";
          ProtectHome = true;
          PrivateTmp = true;
        };
      };
      write-caddy-env = {
        description = "Render /etc/caddy/env from secrets";
        wantedBy = [ "multi-user.target" ];
        before = [ "caddy.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = pkgs.writeShellScript "write-caddy-env" ''
            set -eu
            install -o root -g caddy -m 0640 /dev/null ${envFile}
            {
              echo "AWS_REGION=$(cat /run/secrets/aws_acm/moon/caddy/aws_region)"
              echo "AWS_ACCESS_KEY_ID=$(cat /run/secrets/aws_acm/moon/caddy/aws_access_key_id)"
              echo "AWS_SECRET_ACCESS_KEY=$(cat /run/secrets/aws_acm/moon/caddy/aws_secret_access_key)"
            } > ${envFile}
          '';
        };
      };
    };

    # Enable custom Caddy package with Route 53 plugin
    services.caddy = {
      enable = true;
      package = import ../../../pkgs/caddy-with-route53.nix { inherit pkgs lib; };
      configFile = "/etc/caddy/Caddyfile";
    };
  };
}

