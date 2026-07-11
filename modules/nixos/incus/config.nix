{ lib, config, pkgs, userConfig, ... }:

let
  cfg = config.mine.incus;

  # Store copy used only as a systemd restart trigger. The sync script
  # intentionally reads cfg.profileDir at runtime so applied profiles match the
  # operational checkout path also referenced by cloud-init seed disk devices.
  profileTriggerStore =
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
    pruned=0
    prune_failed=0
    unchanged=0
    declare -A desired_profiles

    for yaml in "''${yaml_files[@]}"; do
      name="$(basename "$yaml" .yaml)"
      desired=$(cat "$yaml")
      desired_profiles["$name"]=1

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

    ${lib.optionalString cfg.pruneRetiredProfiles ''
      live_profiles="$($INCUS profile list --format csv -c n)"
      while IFS= read -r profile; do
        [ -z "$profile" ] && continue
        [ "$profile" = "default" ] && continue
        if [ -z "''${desired_profiles[$profile]+x}" ]; then
          if delete_output="$($INCUS profile delete "$profile" 2>&1)"; then
            echo "incus-profile-sync: PRUNED retired profile '$profile'"
            pruned=$((pruned + 1))
          else
            echo "incus-profile-sync: WARNING failed to prune retired profile '$profile': $delete_output"
            prune_failed=$((prune_failed + 1))
          fi
        fi
      done <<< "$live_profiles"
    ''}

    total=''${#yaml_files[@]}
    echo "incus-profile-sync: $total profiles — $created created, $changed overwritten, $unchanged unchanged, $pruned pruned, $prune_failed prune failures"
  '';
in
{
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
    # Trigger rerun whenever YAML content changes in the store snapshot; the
    # script still applies the current checkout content from cfg.profileDir.
    restartTriggers = [ profileTriggerStore ];
    serviceConfig = {
      Type = "oneshot";
      # Wait up to 30s for incus daemon to become ready before syncing profiles
      ExecStartPre = "${pkgs.bash}/bin/bash -c 'for i in $(seq 1 30); do ${pkgs.incus}/bin/incus info &>/dev/null && exit 0; sleep 1; done; echo incus-profile-sync: timed out waiting for incus; exit 1'";
      ExecStart = profileSyncScript;
    };
  };

  # set secrets
  sops.secrets = lib.mkIf config.mine.sops.available (
    lib.genAttrs [
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
}
