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

    systemd.services.${svc} = {
      # Wait for storage pool and our staged secrets before starting
      requires = [ "mnt-crownstore.mount" ];
      after = [ "mnt-crownstore.mount" ];
      serviceConfig = {
        # Double check that the storage pool is actually there
        ExecStartPre = "${pkgs.coreutils}/bin/test -d /mnt/crownstore/incus";
      };
    };
  };
}

## { lib, config, pkgs, userConfig, ... }:
## let
##   svc = "incus";
##   cfg = config.mine.${svc};
## in
## {
##   options.mine.incus = {
##     enable = lib.mkEnableOption "virtualization.incus module";
##   };
## 
##   config = lib.mkIf cfg.enable {
##     # Enable user namespaces, required for Incus to perform UID/GID mapping
##     # or I just don't pass /run/secrets directly through to instances
##     # boot.kernel.sysctl = {
##     #   "user.max_user_namespaces" = 28633;
##     # };
##     virtualisation = {
##       ${svc} = {
##         enable = true;
##         agent.enable = false;
##         ui.enable = true;
##       };
##       libvirtd.enable = true;
##     };
##     systemd.services.${svc} = {
##       # Wait for storage pool availability before starting incus...
##       requires = [ "mnt-crownstore.mount" ];
##       after = [ "mnt-crownstore.mount" "incus-secrets.service" ];
##       serviceConfig = {
##         # ...and double check that it's there
##         ExecStartPre = "${pkgs.coreutils}/bin/test -d /mnt/crownstore/incus";
##       };
##     };
##     users.users.${userConfig.username} = {
##       extraGroups = [ "incus-admin" ];
##     };
## 
##     # Pass sops-nix secrets through for incus instance consumption
##     systemd.services.incus-secrets = {
##       description = "Stage sops secrets for incus instance consumption";
##       wantedBy = [ "multi-user.target" ];
##       after = [ "sops-nix.service" ];
##       requires = [ "sops-nix.service" ];
##   
##       script = ''
##         set -euo pipefail
##         
##         # Define the staging directory on the host
##         STAGING_DIR="/run/incus-secrets/"
##         
##         # Create the directory and set permissions that are easy for Incus to map
##         mkdir -p "$STAGING_DIR"
##         chmod 755 /run/incus-secrets
##         chmod 755 "$STAGING_DIR"
##         
##         # Copy the secret from the sops-nix path to the staging path
##         # and set readable permissions for the 'incus' group on the host.
##         cp ${config.sops.secrets."pocket-id/admin_password".path} "$STAGING_DIR/pocket-id/admin_password"
##         chown root:incus "$STAGING_DIR/admin_password"
##         chmod 0440 "$STAGING_DIR/admin_password"
##       '';
##   
##       serviceConfig = {
##         Type = "oneshot";
##         RemainAfterExit = true; # Keep the service "active" to satisfy dependencies
##       };
##     };
## 
##   };
## }

