#!/usr/bin/env python3
"""Build LXC images defined in flake, then incus import.

Interactive:  containers/build.py [names...]   Build specified (or all) containers
Nightly:      containers/build.py --nightly    Build only running incus instances
"""

import argparse
import json
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

TMP_BASE = Path("/tmp/lxc")
SCRIPT_DIR = Path(__file__).resolve().parent
FLAKE_DIR = SCRIPT_DIR.parent
CONTAINERS_DIR = SCRIPT_DIR
INSTANCE_MAP_FILE = FLAKE_DIR / "hosts/crown/incus-instances/instance_map.json"

# Containers that should be pushed to remote incus servers after local import.
# Maps container name -> list of remote names (as configured via `incus remote`).
REMOTE_TARGETS = {
    "spire": ["saguaro"],
}


def run(cmd, check=True):
    """Run a command and return (stdout, stderr)."""
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if check and result.returncode != 0:
        print(f"  Command failed: {' '.join(cmd)}")
        print(f"  Error: {result.stderr.strip()}")
        raise subprocess.CalledProcessError(result.returncode, cmd)
    return result.stdout.strip(), result.stderr.strip()


def get_containers():
    """Discover buildable containers from containers/*.nix filenames.

    Every .nix file directly under containers/ is a buildable LXC image.
    Base layers and add-ons live in containers/lib/ and are excluded.

    Returns:
        list of str: sorted container names (kebab-case, no extension)
    """
    if not CONTAINERS_DIR.exists():
        return []
    return sorted(f.stem for f in CONTAINERS_DIR.glob("*.nix"))


def get_instance_map():
    """Load instance name -> flake attribute mappings from instance_map.json.

    Used when incus instance names don't match container filenames.
    e.g. {"mv-seattle": "tailnet-exit", "mv-oslo": "tailnet-exit"}

    Returns:
        dict: instance name -> flake attribute name
    """
    if not INSTANCE_MAP_FILE.exists():
        return {}
    return json.loads(INSTANCE_MAP_FILE.read_text(encoding="utf-8"))


def get_running_instances():
    """Get list of running incus instance names.

    Returns:
        list of str: instance names, or empty list if incus unavailable
    """
    try:
        stdout, _ = run(
            ["incus", "list", "-c", "n", "--format", "csv", "status=RUNNING"],
            check=False,
        )
        return [line.strip() for line in stdout.splitlines() if line.strip()]
    except FileNotFoundError:
        return []


def resolve_nightly_targets():
    """Determine which containers to build based on running incus instances.

    Matches running instance names to container .nix files (direct match)
    or uses instance_map.json for non-obvious mappings (e.g. mv-seattle -> tailnet-exit).

    Returns:
        list of str: deduplicated, sorted container attribute names to build
    """
    available = set(get_containers())
    instance_map = get_instance_map()
    running = get_running_instances()

    if not running:
        print("No running incus instances found")
        return []

    targets = set()
    for instance in running:
        if instance in instance_map:
            attr = instance_map[instance]
            if attr in available:
                targets.add(attr)
                print(f"  {instance} -> {attr} (mapped)")
            else:
                print(f"  {instance} -> {attr} (mapped, but no container file)")
        elif instance in available:
            targets.add(instance)
            print(f"  {instance} (direct match)")
        else:
            print(f"  {instance} (skipped, no match)")

    return sorted(targets)


def next_version(name):
    """Return the next build version number for a container."""
    base = TMP_BASE / name
    if not base.exists():
        return 1
    versions = [int(d.name) for d in base.iterdir() if d.is_dir() and d.name.isdigit()]
    return max(versions, default=0) + 1


def find_tarball(result_dir):
    """Find the single .tar.xz in a nix build result."""
    tarball_dir = result_dir / "tarball"
    tarballs = list(tarball_dir.glob("*.tar.xz"))
    if len(tarballs) != 1:
        raise FileNotFoundError(
            f"Expected 1 tarball in {tarball_dir}, found {len(tarballs)}"
        )
    return tarballs[0]


def push_to_remotes(name, remotes, dry_run=False):
    """Push a locally imported image to remote incus servers.

    Deletes the existing alias on the remote first, then copies.

    Args:
        name: image alias name
        remotes: list of remote server names
        dry_run: if True, only print what would happen
    """
    for remote in remotes:
        if dry_run:
            print(f"  incus image alias delete {remote}:{name}")
            print(f"  incus image copy local:{name} {remote}: --alias {name}")
            continue

        print(f"  Pushing to {remote}...")

        # Delete existing alias (ignore errors if it doesn't exist)
        run(
            ["incus", "image", "alias", "delete", f"{remote}:{name}"],
            check=False,
        )

        # Copy image to remote
        _, stderr = run(
            ["incus", "image", "copy", f"local:{name}", f"{remote}:", "--alias", name],
            check=False,
        )
        if stderr and "error" in stderr.lower():
            print(f"  WARNING: Push to {remote} failed: {stderr}")
        else:
            print(f"  Pushed to {remote}")


def build_and_import(name, dry_run=False):
    """Build a container image + metadata, import locally, and push to remotes.

    Args:
        name: container name (kebab-case, matches flake attribute and filename)
        dry_run: if True, only print what would be built
    """
    print(f"\n{'=' * 50}")
    print(f"  {name}")
    print(f"{'=' * 50}")

    if dry_run:
        print(f"  nix build .#{name}")
        print(f"  nix build .#{name}-metadata")
        print(f"  incus image import ... --alias {name}")
        if name in REMOTE_TARGETS:
            push_to_remotes(name, REMOTE_TARGETS[name], dry_run=True)
        return

    version = next_version(name)
    tmp_dir = TMP_BASE / name / str(version)
    tmp_dir.mkdir(parents=True, exist_ok=True)
    result_link = Path("result")

    flake_ref = str(FLAKE_DIR)

    # Build rootfs
    print(f"  Building .#{name} ...")
    run(["nix", "build", f"{flake_ref}#{name}"])
    root_target = tmp_dir / "root.tar.xz"
    shutil.copy2(find_tarball(result_link), root_target)

    # Build metadata
    print(f"  Building .#{name}-metadata ...")
    run(["nix", "build", f"{flake_ref}#{name}-metadata"])
    metadata_target = tmp_dir / "metadata.tar.xz"
    shutil.copy2(find_tarball(result_link), metadata_target)

    # Import to local incus
    import_cmd = [
        "incus",
        "image",
        "import",
        str(metadata_target),
        str(root_target),
        "--alias",
        name,
    ]
    print(f"  Importing as '{name}' ...")
    stdout, stderr = run(import_cmd, check=False)
    if "Image with same fingerprint already exists" in stderr:
        print("  Already up to date (fingerprint unchanged)")
    elif stdout:
        print(f"  {stdout}")

    # Push to remote servers if configured
    if name in REMOTE_TARGETS:
        push_to_remotes(name, REMOTE_TARGETS[name])

    print(f"  Done: {name} v{version}")


def resolve_targets(args, available):
    """Determine which containers to build based on CLI arguments.

    Returns:
        list of str: container names to build
    """
    if args.nightly:
        print("\nNightly mode: matching running instances to containers")
        targets = resolve_nightly_targets()
        if not targets:
            print("Nothing to build")
            sys.exit(0)
        return targets

    if args.containers:
        targets = []
        for req in args.containers:
            if req in available:
                targets.append(req)
            else:
                print(f"Unknown container: {req}")
                print(f"Available: {', '.join(available)}")
                sys.exit(1)
        return targets

    return available


def main():
    """Parse arguments and build/import selected LXC containers."""
    parser = argparse.ArgumentParser(
        description="Build and import LXC images from flake"
    )
    parser.add_argument(
        "containers",
        nargs="*",
        help="Containers to build (by name). Omit to build all.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Show what would be built without building",
    )
    parser.add_argument(
        "--list", action="store_true", help="List available containers and exit"
    )
    parser.add_argument(
        "--nightly",
        action="store_true",
        help="Nightly mode: only build containers with running incus instances",
    )
    args = parser.parse_args()

    print(f"LXC Builder - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    available = get_containers()
    if not available:
        print("No containers found in containers/")
        sys.exit(1)

    if args.list:
        print(f"\nAvailable containers ({len(available)}):")
        for name in available:
            remotes = REMOTE_TARGETS.get(name)
            suffix = f"  -> {', '.join(remotes)}" if remotes else ""
            print(f"  {name}{suffix}")
        sys.exit(0)

    targets = resolve_targets(args, available)
    print(f"\nBuilding {len(targets)} container(s): {', '.join(targets)}")

    failed = []
    for name in targets:
        try:
            build_and_import(name, dry_run=args.dry_run)
        except (subprocess.CalledProcessError, FileNotFoundError) as exc:
            failed.append(name)
            print(f"  FAILED: {name} ({exc})")

    passed = len(targets) - len(failed)
    print(f"\nFinished: {passed}/{len(targets)} succeeded")
    if failed:
        print(f"Failed: {', '.join(failed)}")
        sys.exit(1)


if __name__ == "__main__":
    main()
