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
    virtualisation.${svc} = {
      enable = true;
      preseed = {
        config = {
          "core.https_address" = "0.0.0.0:8443";
        };
        storage_pools = [
          {
            name = "moonstore";
            driver = "dir";
            config = {
              source = "/mnt/moonstore/incus";
            };
          }
        ];

        networks = [ ];
        profiles = [
          {
            name = "default";
            config = { };

            devices = {
              "root" = {
                type = "disk";
                path = "/";
                pool = "moonstore";
              };

              "eth0" = {
                type = "nic";
                nictype = "bridged";
                parent = "br1";
                name = "eth0";
              };
            };
          }
        ];
      };
      ui.enable = true;
    };
    systemd.services.${svc} = {
      # Wait for storage pool availability before starting incus...
      requires = [ "moonstore.service" ];
      after = [ "moonstore.service" ];
      serviceConfig = {
        # ...and double check that it's there
        ExecStartPre = "${pkgs.coreutils}/bin/test -d /mnt/moonstore/incus";
      };
    };
    users.users.${userConfig.username} = {
      extraGroups = [ "incus-admin" ];
    };
    networking = {
      nftables.enable = true;
      firewall = {
        enable = true;
        checkReversePath = "loose";
        trustedInterfaces = [ "tailscale0" ];
        allowPing = true;
      };
    };
  };
}

