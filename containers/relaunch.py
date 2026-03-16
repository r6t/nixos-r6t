#!/usr/bin/env python3
"""Relaunch running incus LXC containers with fresh images.

Run on the incus host (crown or saguaro) after building new images.
Persistent data survives — it's on bind-mounted host storage.

Usage:
  containers/relaunch.py                     Relaunch containers with newer images
  containers/relaunch.py spire ntfy          Relaunch specific containers
  containers/relaunch.py --all               Relaunch all even if image unchanged
  containers/relaunch.py --dry-run           Preview what would be relaunched
"""

import argparse
import json
import socket
import subprocess
import sys
import time
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
FLAKE_DIR = SCRIPT_DIR.parent


def get_instance_map():
    """Load instance name -> image alias mappings for the current host.

    Many incus instances share a single image (e.g. mv-seattle, mv-oslo
    both use the 'tailnet-exit' image). instance_map.json stores these
    mappings per host under hosts/<hostname>/incus-instances/.

    Returns:
        dict: instance name -> image alias name
    """
    hostname = socket.gethostname()
    map_file = FLAKE_DIR / "hosts" / hostname / "incus-instances" / "instance_map.json"
    if not map_file.exists():
        return {}
    return json.loads(map_file.read_text(encoding="utf-8"))


def resolve_image_alias(name, instance_map):
    """Resolve an instance name to its image alias.

    Args:
        name: incus instance name
        instance_map: dict from get_instance_map()

    Returns:
        str: the image alias to look up
    """
    return instance_map.get(name, name)


def run(cmd, check=True):
    """Run a command and return (stdout, stderr)."""
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if check and result.returncode != 0:
        return None, result.stderr.strip()
    return result.stdout.strip(), result.stderr.strip()


def get_running_lxc_containers():
    """Get names of running LXC containers (excludes VMs)."""
    stdout, _ = run(
        [
            "incus",
            "list",
            "type=container",
            "status=running",
            "-c",
            "n",
            "--format",
            "csv",
        ]
    )
    if not stdout:
        return []
    return [line.strip() for line in stdout.splitlines() if line.strip()]


def get_image_fingerprint(alias):
    """Get the fingerprint of an image by alias. Returns None if not found."""
    stdout, _ = run(["incus", "image", "list", alias, "--format", "csv", "-c", "f,l"])
    if not stdout:
        return None
    # Filter to exact alias match — positional filter is a substring match,
    # so "llm" would also match "ollama" etc.
    for line in stdout.splitlines():
        parts = line.split(",", 1)
        if len(parts) == 2 and parts[1].strip() == alias:
            return parts[0].strip()
    return None


def get_instance_base_image(name):
    """Get the base image fingerprint an instance was created from."""
    stdout, _ = run(["incus", "config", "get", name, "volatile.base_image"])
    return stdout if stdout else None


def profile_exists(name):
    """Check if an incus profile exists."""
    _, stderr = run(["incus", "profile", "show", name], check=False)
    return "not found" not in (stderr or "")


def stop_delete_launch(name, image_alias):
    """Stop, delete, and relaunch a container.

    Args:
        name: incus instance name
        image_alias: image alias to launch from (may differ from name)

    Returns:
        str: 'relaunched' or 'failed'
    """
    if not profile_exists(name):
        print(f"  ERROR: No profile '{name}' found, skipping (would lose config)")
        return "failed"

    # Stop
    print("  Stopping...")
    _, stderr = run(["incus", "stop", name, "--timeout", "30"], check=False)
    if stderr and "deadline" in stderr:
        print("  Graceful stop timed out, forcing...")
        run(["incus", "stop", name, "--force"], check=False)

    # Delete
    print("  Deleting...")
    _, stderr = run(["incus", "delete", name], check=False)
    if stderr:
        print(f"  ERROR: Failed to delete: {stderr}")
        return "failed"

    # Launch
    print(f"  Launching from image '{image_alias}' with profile '{name}'...")
    _, stderr = run(
        ["incus", "launch", image_alias, name, "--profile", name], check=False
    )
    if stderr and "error" in stderr.lower():
        print(f"  ERROR: Failed to launch: {stderr}")
        return "failed"

    # Verify
    time.sleep(3)
    stdout, _ = run(["incus", "list", name, "-c", "s,4", "--format", "csv"])
    if stdout and "RUNNING" in stdout:
        ip_info = stdout.split(",", 1)[1] if "," in stdout else ""
        print(f"  RUNNING {ip_info}")
        return "relaunched"

    print(f"  WARNING: Status after relaunch: {stdout}")
    return "failed"


def check_and_relaunch(name, image_alias, force=False, dry_run=False):
    """Check if a container needs relaunching and do it.

    Args:
        name: incus instance name
        image_alias: image alias to look up and launch from
        force: relaunch even if image unchanged
        dry_run: preview without acting

    Returns:
        str: "relaunched", "unchanged", "skipped", or "failed"
    """
    image_fp = get_image_fingerprint(image_alias)
    if not image_fp:
        print(f"  No image alias '{image_alias}' found, skipping")
        return "skipped"

    instance_fp = get_instance_base_image(name)
    needs_relaunch = force or (instance_fp != image_fp)

    if not needs_relaunch:
        return "unchanged"

    if instance_fp and not force:
        print(f"  Current: {instance_fp[:12]}")
    print(f"  New:     {image_fp[:12]}{' (forced)' if force else ''}")

    if dry_run:
        print("  [dry-run] Would stop, delete, and relaunch")
        return "relaunched"

    return stop_delete_launch(name, image_alias)


def main():
    """Parse arguments and relaunch containers."""
    parser = argparse.ArgumentParser(
        description="Relaunch running incus LXC containers with fresh images"
    )
    parser.add_argument("containers", nargs="*", help="Specific containers to relaunch")
    parser.add_argument(
        "--all",
        action="store_true",
        help="Relaunch all running LXCs even if image unchanged",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Preview what would be relaunched",
    )
    args = parser.parse_args()

    print("Incus Container Relaunch")
    print("=" * 50)

    instance_map = get_instance_map()
    if instance_map:
        print(f"Loaded instance map ({len(instance_map)} mappings)")

    running = get_running_lxc_containers()
    if not running:
        print("No running LXC containers found")
        sys.exit(0)

    # Filter to requested containers
    if args.containers:
        targets = []
        for name in args.containers:
            if name in running:
                targets.append(name)
            else:
                print(f"WARNING: {name} is not a running LXC container")
        running = targets

    if not running:
        print("No matching containers to relaunch")
        sys.exit(0)

    results = {"relaunched": 0, "unchanged": 0, "skipped": 0, "failed": 0}

    for name in sorted(running):
        image_alias = resolve_image_alias(name, instance_map)
        suffix = f" (image: {image_alias})" if image_alias != name else ""
        print(f"\n{'━' * 50}")
        print(f"  {name}{suffix}")
        print(f"{'━' * 50}")

        result = check_and_relaunch(
            name, image_alias, force=args.all, dry_run=args.dry_run
        )
        if result == "unchanged":
            print("  Image unchanged, skipping")
        results[result] = results.get(result, 0) + 1

    print(f"\n{'=' * 50}")
    print(
        f"Results: {results['relaunched']} relaunched, "
        f"{results['unchanged']} unchanged, "
        f"{results['skipped']} skipped, "
        f"{results['failed']} failed"
    )

    if results["failed"] > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
