#!/usr/bin/env python3
"""
Build LXC images defined in flake, then incus import
"""

import glob
import shutil
import subprocess
from datetime import datetime
from pathlib import Path


def run_command(cmd, check=True):
    """Run a shell command and return its stdout and stderr."""
    try:
        result = subprocess.run(
            cmd, shell=True, capture_output=True, text=True, check=check
        )
        return result.stdout.strip(), result.stderr.strip()
    except subprocess.CalledProcessError as e:
        if check:
            print(f"Command failed: {cmd}")
            print(f"Error: {e.stderr}")
            raise
        return e.stdout, e.stderr


def kebab_to_camel(name):
    """Convert kebab-case string to camelCase."""
    parts = name.split("-")
    return parts[0] + "".join(word.capitalize() for word in parts[1:])


def get_container_names():
    """Get container names from containers/*.nix excluding r6-lxc* files.

    Returns:
        list of tuples: (camelCase_name, kebab-case_name)
    """
    containers_dir = Path("containers")
    if not containers_dir.exists():
        print("containers/ directory not found")
        return []

    nix_files = [
        f for f in containers_dir.glob("*.nix") if not f.stem.startswith("r6-lxc")
    ]
    containers = []
    for f in nix_files:
        kebab_name = f.stem
        camel_name = kebab_to_camel(kebab_name) if "-" in kebab_name else kebab_name
        containers.append((camel_name, kebab_name))
    print(f"Discovered containers: {containers}")
    return containers


def get_next_version_number(container_name):
    """Return the next available build version number for a container.

    Args:
        container_name (str): kebab-case container name

    Returns:
        int: next version number
    """
    base_path = Path(f"/tmp/lxc/{container_name}")
    if not base_path.exists():
        return 1
    versions = [
        int(d.name) for d in base_path.iterdir() if d.is_dir() and d.name.isdigit()
    ]
    return max(versions, default=0) + 1


def build_and_deploy_container(camel_name, kebab_name):
    """Build the container and its metadata, copy artifacts, and import to incus.

    Args:
        camel_name (str): camelCase nix flake attribute name
        kebab_name (str): kebab-case container name for path and alias
    """
    print(f"=== Building {camel_name} (file: {kebab_name}) ===")
    version = get_next_version_number(kebab_name)
    tmp_dir = Path(f"/tmp/lxc/{kebab_name}/{version}")
    tmp_dir.mkdir(parents=True, exist_ok=True)

    print(f"Building .#{camel_name}...")
    run_command(f"nix build .#{camel_name}")
    container_tarball = glob.glob("result/tarball/*.tar.xz")[0]
    root_target = tmp_dir / "root.tar.xz"
    shutil.copy2(container_tarball, root_target)

    print(f"Building .#{camel_name}Metadata...")
    run_command(f"nix build .#{camel_name}Metadata")
    metadata_tarball = glob.glob("result/tarball/*.tar.xz")[0]
    metadata_target = tmp_dir / "metadata.tar.xz"
    shutil.copy2(metadata_tarball, metadata_target)

    alias_name = kebab_name.replace("_", "-").replace(".", "-")
    import_cmd = (
        f"incus image import {metadata_target} {root_target} --alias {alias_name}"
    )
    print(f"Importing to incus: {import_cmd}")
    stdout, stderr = run_command(import_cmd, check=False)
    if "Image with same fingerprint already exists" in stderr:
        print(
            f"🔄 Image {camel_name} was already up to date. This build wasn't necessary."
        )
    else:
        print(stdout)

    print(f"✅ Incus image alias {alias_name} set from version {version}")


def main():
    """Start building and deploying all containers from the containers/ directory."""
    print("🚀 Build and deploy LXC images")
    print(f"Timestamp: {datetime.now().isoformat()}")

    containers = get_container_names()
    if not containers:
        print("No containers found to build")
        return

    for camel_name, kebab_name in containers:
        build_and_deploy_container(camel_name, kebab_name)


if __name__ == "__main__":
    main()
