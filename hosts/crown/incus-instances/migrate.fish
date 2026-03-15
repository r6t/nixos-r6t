#!/usr/bin/env fish
# Migrate crown incus instances from old numbered profiles to new IaC profiles.
# Run this ON crown from the nixos-r6t repo root.
#
# This script:
#   1. Creates new profiles from YAML files in this directory
#   2. Stops each instance
#   3. Reassigns from old profile to new
#   4. Starts the instance
#   5. Verifies it came up
#   6. Prompts before continuing to the next instance
#
# Old profiles are NOT deleted — clean those up manually after verification.

set PROFILE_DIR (realpath (dirname (status filename)))

# Instance -> old profile name mapping
set -l instances \
    audiobookshelf:131-br1-audiobookshelf \
    changedetection:99-br1-changedetection \
    immich:130-br1-immich \
    it-tools:103-br1-ittools \
    jellyfin:100-br1-jellyfin \
    ladder:104-br1-ladder \
    llm:134-br1-llm \
    miniflux:105-br1-miniflux \
    mv-oslo:6-mv-oslo \
    mv-seattle:4-mv-seattle \
    mv-vancouver:5-mv-vancouver \
    mv-zurich:7-mv-zurich \
    ntfy:106-br1-ntfy \
    paperless:106-br1-paperless \
    pirate-ship:162-br1-pirate-ship \
    pocket-id:133-br1-pocket-id \
    searxng:101-br1-searxng \
    sts:194-br1-sts

set total (count $instances)
set succeeded 0
set failed 0

echo "Crown Incus Profile Migration"
echo "=============================="
echo "Profile source: $PROFILE_DIR"
echo "Instances to migrate: $total"
echo ""

for entry in $instances
    set name (string split ':' $entry)[1]
    set old_profile (string split ':' $entry)[2]
    set yaml "$PROFILE_DIR/$name.yaml"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $name  ($old_profile -> $name)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    if not test -f $yaml
        echo "  ERROR: $yaml not found, skipping"
        set failed (math $failed + 1)
        continue
    end

    # Step 1: Create new profile
    echo "  Creating profile '$name'..."
    if incus profile show $name &>/dev/null
        echo "  Profile '$name' already exists, updating..."
        incus profile edit $name < $yaml
    else
        incus profile create $name
        incus profile edit $name < $yaml
    end

    if test $status -ne 0
        echo "  ERROR: Failed to create/update profile"
        set failed (math $failed + 1)
        continue
    end

    # Step 2: Check instance exists and is running
    set instance_status (incus list $name -c s --format csv 2>/dev/null)
    if test -z "$instance_status"
        echo "  WARNING: Instance '$name' does not exist, profile created but nothing to migrate"
        set succeeded (math $succeeded + 1)
        continue
    end

    echo "  Instance status: $instance_status"

    # Step 3: Stop instance
    if test "$instance_status" = "RUNNING"
        echo "  Stopping $name..."
        incus stop $name --timeout 30
        if test $status -ne 0
            echo "  ERROR: Failed to stop $name"
            set failed (math $failed + 1)
            continue
        end
    end

    # Step 4: Reassign profile
    echo "  Reassigning profile: $old_profile -> $name"
    incus profile assign $name $name
    if test $status -ne 0
        echo "  ERROR: Failed to reassign profile"
        echo "  Attempting to restart with old profile..."
        incus start $name
        set failed (math $failed + 1)
        continue
    end

    # Step 5: Start instance
    echo "  Starting $name..."
    incus start $name
    if test $status -ne 0
        echo "  ERROR: Failed to start $name"
        set failed (math $failed + 1)
        continue
    end

    # Step 6: Wait and verify
    sleep 3
    set new_status (incus list $name -c s --format csv 2>/dev/null)
    echo "  Status after start: $new_status"

    if test "$new_status" = "RUNNING"
        # Show network info
        set ip_info (incus list $name -c 4 --format csv 2>/dev/null)
        echo "  Network: $ip_info"
        echo "  OK: $name migrated successfully"
        set succeeded (math $succeeded + 1)
    else
        echo "  WARNING: $name is not RUNNING after migration"
        set failed (math $failed + 1)
    end

    # Prompt before continuing
    echo ""
    read -P "  Continue to next instance? [Y/n] " confirm
    if test "$confirm" = "n" -o "$confirm" = "N"
        echo "  Stopping migration."
        break
    end
end

echo ""
echo "=============================="
echo "Migration complete: $succeeded/$total succeeded, $failed failed"

if test $failed -gt 0
    echo ""
    echo "After verifying all instances, clean up old profiles:"
    echo "  incus profile delete <old-profile-name>"
end
