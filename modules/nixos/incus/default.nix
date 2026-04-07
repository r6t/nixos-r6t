{ lib, config, pkgs, userConfig, ... }:

let
  cfg = config.mine.incus;

  # Copy profile YAMLs into the nix store so changes are tracked by systemd
  profileStore =
    if cfg.profileDir != null
    then
      pkgs.runCommand "incus-profiles" { } ''
        mkdir -p $out
        cp ${cfg.profileDir}/*.yaml $out/ 2>/dev/null || true
      ''
    else null;

  profileSyncScript = pkgs.writeShellScript "incus-profile-sync" ''
    set -euo pipefail

    PROFILE_DIR="${cfg.profileDir}"
    INCUS="${pkgs.incus}/bin/incus"

    if [ ! -d "$PROFILE_DIR" ]; then
      echo "incus-profile-sync: profile directory $PROFILE_DIR does not exist, skipping"
      exit 0
    fi

    shopt -s nullglob
    yaml_files=("$PROFILE_DIR"/*.yaml)

    if [ ''${#yaml_files[@]} -eq 0 ]; then
      echo "incus-profile-sync: no YAML profiles found in $PROFILE_DIR"
      exit 0
    fi

    changed=0
    created=0
    unchanged=0

    for yaml in "''${yaml_files[@]}"; do
      name="$(basename "$yaml" .yaml)"
      desired=$(cat "$yaml")

      if ! $INCUS profile show "$name" &>/dev/null; then
        $INCUS profile create "$name"
        $INCUS profile edit "$name" < "$yaml"
        echo "incus-profile-sync: CREATED profile '$name'"
        created=$((created + 1))
        continue
      fi

      # Compare current live state against desired YAML
      current=$($INCUS profile show "$name")
      if [ "$current" = "$desired" ]; then
        unchanged=$((unchanged + 1))
      else
        $INCUS profile edit "$name" < "$yaml"
        echo "incus-profile-sync: OVERWRITTEN profile '$name' (local state replaced with nix content)"
        changed=$((changed + 1))
      fi
    done

    total=''${#yaml_files[@]}
    echo "incus-profile-sync: $total profiles — $created created, $changed overwritten, $unchanged unchanged"
  '';
in
{
  options.mine.incus = {
    enable = lib.mkEnableOption "virtualization.incus module";

    profileDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to directory containing incus profile YAML files.
        Each .yaml file becomes an incus profile (filename without extension = profile name).
        Profiles are enforced on every nixos-rebuild — local changes are always overwritten.
      '';
    };

  };

  config = lib.mkIf cfg.enable {
    virtualisation.incus = {
      enable = true;
      agent.enable = false;
      ui.enable = true;
    };

    users.users.${userConfig.username} = {
      extraGroups = [ "incus-admin" ];
    };

    # Declarative profile management — runs on every boot and nixos-rebuild
    systemd.services.incus-profile-sync = lib.mkIf (cfg.profileDir != null) {
      description = "Enforce incus profiles from nix-managed YAML files";
      after = [ "incus.service" "incus.socket" "incus-preseed.service" ];
      wants = [ "incus.service" "incus.socket" ];
      wantedBy = [ "multi-user.target" ];
      # Trigger restart whenever YAML content changes in the nix store copy
      restartTriggers = [ profileStore ];
      serviceConfig = {
        Type = "oneshot";
        # Wait up to 30s for incus daemon to become ready before syncing profiles
        ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 30); do ${pkgs.incus}/bin/incus info &>/dev/null && exit 0; sleep 1; done; echo incus-profile-sync: timed out waiting for incus; exit 1'";
        ExecStart = profileSyncScript;
      };
    };

    # set secrets
    sops.secrets = lib.mkIf config.mine.sops.enable (
      lib.genAttrs [
        "caddy/headscale/aws_access_key_id"
        "caddy/headscale/aws_region"
        "caddy/headscale/aws_secret_access_key"
        "caddy/lab/aws_access_key_id"
        "caddy/lab/aws_region"
        "caddy/lab/aws_secret_access_key"
        "grafana/oidc_client_id"
        "grafana/oidc_client_secret"
        "immich/db_password"
        "immich/oidc_client_id"
        "immich/oidc_client_secret"
      ]
        (_: { owner = config.users.users.${userConfig.username}.name; })
    );
  };
}
