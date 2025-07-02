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
    systemd.services.${svc} = {
      # Wait for storage pool availability before starting incus...
      requires = [ "mnt-barrelstore.mount" ];
      after = [ "mnt-barrelstore.mount" ];
      serviceConfig = {
        # ...and double check that it's there
        ExecStartPre = "${pkgs.coreutils}/bin/test -d /mnt/barrelstore/incus";
      };
    };
    users.users.${userConfig.username} = {
      extraGroups = [ "incus-admin" ];
    };
    networking = {
      nftables.enable = true;
      firewall = {
	# enable = true;
        checkReversePath = "loose";
        allowPing = true;
      };
    };
  };
}

