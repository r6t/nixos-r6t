#!/usr/bin/env python3
"""Build LXC images defined in flake, then incus import."""

import argparse
import shutil
import subprocess
import sys
from datetime import datetime
from pathlib import Path

TMP_BASE = Path("/tmp/lxc")
CONTAINERS_DIR = Path("containers")


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


def build_and_import(name, dry_run=False):
    """Build a container image + metadata and import to incus.

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
        return

    version = next_version(name)
    tmp_dir = TMP_BASE / name / str(version)
    tmp_dir.mkdir(parents=True, exist_ok=True)
    result_link = Path("result")

    # Build rootfs
    print(f"  Building .#{name} ...")
    run(["nix", "build", f".#{name}"])
    root_target = tmp_dir / "root.tar.xz"
    shutil.copy2(find_tarball(result_link), root_target)

    # Build metadata
    print(f"  Building .#{name}-metadata ...")
    run(["nix", "build", f".#{name}-metadata"])
    metadata_target = tmp_dir / "metadata.tar.xz"
    shutil.copy2(find_tarball(result_link), metadata_target)

    # Import to incus
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

    print(f"  Done: {name} v{version}")


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
    args = parser.parse_args()

    print(f"LXC Builder - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")

    available = get_containers()
    if not available:
        print("No containers found in containers/")
        sys.exit(1)

    if args.list:
        print(f"\nAvailable containers ({len(available)}):")
        for name in available:
            print(f"  {name}")
        sys.exit(0)

    # Validate requested containers
    if args.containers:
        targets = []
        for req in args.containers:
            if req in available:
                targets.append(req)
            else:
                print(f"Unknown container: {req}")
                print(f"Available: {', '.join(available)}")
                sys.exit(1)
    else:
        targets = available

    print(f"Building {len(targets)} container(s): {', '.join(targets)}")

    for name in targets:
        build_and_import(name, dry_run=args.dry_run)

    print(f"\nFinished: {len(targets)} container(s) processed")


if __name__ == "__main__":
    main()
