# Incus LXC Container System

This document describes how NixOS LXC container images are defined, built, deployed, and managed across incus hosts in this flake. It serves as both a reference for humans and a steering document for LLMs creating new incus roles.

## Architecture Overview

```
containers/*.nix          NixOS definitions (what runs inside the container)
    |
    v
flake.nix                 Auto-generates build targets from containers/*.nix
    |
    v
containers/build.py       Builds images via nix, imports into incus image store
    |                     Auto-pushes to remote hosts (e.g. spire -> saguaro)
    v
containers/relaunch.py    Stops, deletes, relaunches containers with newer images
    |
    v
hosts/{host}/incus-instances/
    {name}.yaml            Incus profile (networking, storage mounts, devices)
    seed/{name}.*          Cloud-init seed files (static IP, hostname)
```

Two hosts run incus:

- **crown** — primary compute server, runs all LXCs
- **saguaro** — router, runs Home Assistant VM only

## Directory Structure

### Container Definitions: `containers/`

Every `.nix` file directly in `containers/` is a buildable LXC image. The flake auto-discovers them — drop a new file here and it becomes a build target.

```
containers/
    audiobookshelf.nix      Buildable image definitions
    miniflux.nix
    spire.nix
    tailnet-exit.nix
    ...
    lib/                    Shared base layers and add-ons (NOT buildable images)
        base.nix            Common LXC base: cloud-init, dnsmasq, packages, fish
        caddy-routes.nix    Single source of truth for all caddy reverse proxy routes
        dns-overrides.nix   LAN DNS overrides (*.r6t.io -> crown's caddy)
        mullvad-dns.nix     Stubby DoT resolver via Mullvad (port 5353)
        nextdns.nix         NextDNS resolver (port 5353)
        wg-exit-node.nix    WireGuard + exit-node routing + tailscale auto-join base
    build.py                Build images, import locally, push to remotes
    relaunch.py             Relaunch running containers with newer images
```

### Instance Profiles: `hosts/{host}/incus-instances/`

Incus profile YAML files define the runtime environment — how the container connects to the network, what host directories are mounted in, and what ports are exposed. Profiles are **declaratively managed** — `nixos-rebuild switch` automatically syncs all YAML profiles into incus, overwriting any local changes.

```
hosts/saguaro/incus-instances/
    haos.yaml               Home Assistant VM
    seed/
        (no LXC containers on saguaro)
```

### Build Tooling

- **`flake.nix`** — auto-generates `nix build .#<name>` and `nix build .#<name>-metadata` targets for every `containers/*.nix` file
- **`containers/build.py`** — builds images and imports them into incus. Supports `--list`, `--dry-run`, `--nightly`, and building specific containers by name. Auto-pushes to remote hosts via `REMOTE_TARGETS` dict.
- **`containers/relaunch.py`** — compares image fingerprints and relaunches containers that have newer images. Supports `--all` (force), `--dry-run`, and specific container names.
- **`hosts/crown/incus-instances/instance_map.json`** — maps incus instance names to container build targets when they differ (e.g. `mv-seattle` -> `tailnet-exit`, `pirate-ship` -> `docker`)

## How to Create a New Container

### Step 1: Create the NixOS definition

Create `containers/{name}.nix`. Every container imports the base layer and a DNS resolver:

```nix
{ ... }:

{
  imports = [
    ./lib/base.nix            # Always required
    ./lib/mullvad-dns.nix     # Or ./lib/nextdns.nix for NextDNS
    # Add module imports for services this container needs:
    # ../modules/nixos/{module}/default.nix
  ];

  networking.hostName = "{name}";

  # Service configuration
  # ...

  # Firewall: only open ports if the service needs LAN access.
  # Containers on the tailnet get all ports open via tailscale0 trusted interface.
  # networking.firewall.allowedTCPPorts = [ 8080 ];
}
```

Key patterns:

- Import `./lib/base.nix` — provides cloud-init, dnsmasq, common packages, fish shell
- Import `./lib/mullvad-dns.nix` — provides Mullvad DoT on port 5353 (most containers use this)
- Import modules from `../modules/nixos/` for services (caddy, tailscale, etc.)
- The base layer imports `./lib/dns-overrides.nix` automatically — this resolves `*.r6t.io` to crown's caddy IP so containers can reach reverse-proxied services
- `networking.hostName` must match the filename (without `.nix`)
- Persistent data directories should use conventional paths (`/var/lib/{service}`) — actual storage is bind-mounted by the incus profile

### Step 2: Add caddy routes (if the container has a web service)

Add routes to `containers/lib/caddy-routes.nix`:

```nix
myapp = {
  "myapp.r6t.io" = { upstream = "http://localhost:8080"; };
};
```

Then add the container name to the `crownContainers` list in `hosts/crown/configuration.nix`.

### Step 3: Build the image

```fish
python3 containers/build.py {name}
```

The builder produces two tarballs (rootfs + metadata) and imports them into the local incus image store with alias `{name}`. If the container is in `REMOTE_TARGETS` (in `build.py`), the image is also pushed to remote hosts.

### Step 4: Create the incus profile

Create `hosts/{host}/incus-instances/{name}.yaml`:

```yaml
config:
  security.nesting: "true"
  user.user-data: |
    #cloud-config
    datasource_list: [NoCloud, None]
description: { name }
devices:
  eth0:
    name: eth0
    nictype: bridged # "bridged" for app containers on crown (br1)
    parent: br1 # "physical" + parent: exit0-3 for exit nodes
    type: nic
  root:
    path: /
    pool: default # "default" on crown, "kingston-pool" on saguaro
    type: disk
  seed-meta-data:
    path: /var/lib/cloud/seed/nocloud/meta-data
    source: /home/r6t/git/nixos-r6t/hosts/{host}/incus-instances/seed/{name}.meta-data
    type: disk
  seed-network-config:
    path: /var/lib/cloud/seed/nocloud/network-config
    source: /home/r6t/git/nixos-r6t/hosts/{host}/incus-instances/seed/{name}.network-config
    type: disk
  seed-user-data:
    path: /var/lib/cloud/seed/nocloud/user-data
    source: /home/r6t/git/nixos-r6t/hosts/{host}/incus-instances/seed/{name}.user-data
    type: disk
  # Persistent storage (bind mounts from host):
  #   {name}-data:
  #     path: /var/lib/{service}
  #     shift: "true"
  #     source: /mnt/crownstore/app-storage/{name}
  #     type: disk
  # Port forwarding (proxy devices) for host-mode caddy:
  #   {name}-port:
  #     connect: tcp:127.0.0.1:8080
  #     listen: tcp:0.0.0.0:8080
  #     type: proxy
name: { name }
```

Profiles are auto-synced to incus on every `nixos-rebuild switch` via the `incus-profile-sync` service. No manual `incus profile create` needed.

### Step 5: Create seed files

Create three files in `hosts/{host}/incus-instances/seed/`:

**`{name}.meta-data`**:

```
instance-id: {name}
local-hostname: {name}
```

**`{name}.network-config`**:

```yaml
version: 2
ethernets:
  eth0:
    dhcp4: false
    dhcp6: false
    addresses:
      - 192.168.6.{IP}/24
    routes:
      - to: 0.0.0.0/0
        via: 192.168.6.{GATEWAY}
    nameservers:
      addresses:
        - 127.0.0.1
```

**`{name}.user-data`**:

```yaml
#cloud-config
preserve_hostname: false
hostname: { name }
manage_etc_hosts: true
```

### Step 6: Launch the instance

```fish
# Profile is already synced by nixos-rebuild. Just launch:
incus launch {name} {name} --profile {name}
```

### Step 7: Update instance_map.json (if needed)

If the incus instance name differs from the container build target name (e.g. multiple instances from one image, or Docker-based instances), add a mapping to `hosts/crown/incus-instances/instance_map.json`:

```json
{
  "mv-seattle": "tailnet-exit",
  "pirate-ship": "docker"
}
```

## Network Topology

All containers use static IPs on the 192.168.6.0/24 LAN. DHCP pool is 11-89; static assignments are outside this range.

### Gateway Routing

Most app containers route through Mullvad WireGuard exit nodes for privacy:

```
App container  -->  Exit node container (WireGuard)  -->  Saguaro (router)  -->  Internet
  .91-.104            .4-.7 (mv-*)                          .1
```

Exit nodes have dedicated physical NICs (Intel I226-V, pinned by PCI path as `exit0`-`exit3`). App containers use the br1 bridge.

### DNS Resolution

Every container runs a local dnsmasq instance on port 53 that:

1. Resolves `*.r6t.io` to crown's caddy IP (`192.168.6.10`) via `containers/lib/dns-overrides.nix` (**LAN only**). Containers with Tailscale enabled bypass this to use the encrypted tailnet path.
2. Forwards all other queries to an upstream resolver on port 5353 — either Mullvad DoT (`lib/mullvad-dns.nix`) or NextDNS (`lib/nextdns.nix`)
3. **Split-DNS for MagicDNS**: Forwards `*.ts.net` queries directly to Tailscale's resolver at `100.100.100.100` (handled automatically by `mine.tailscale.magicDnsDomain`).

Crown's caddy handles most `*.r6t.io` services directly (local containers via proxy devices). For services on spire (PocketID), crown's caddy proxies to spire over the tailnet using MagicDNS names (`http://spire.r6t.io:1411`).

### Caddy Reverse Proxy

All caddy routes are declared in `containers/lib/caddy-routes.nix` — a single source of truth.

**Host mode (crown)**: Caddy runs on the host. Routes from `caddy-routes.nix` generate `services.caddy.virtualHosts` at build time. The caddy module defaults to Route53 DNS challenge with credentials from an environment file. Crown proxies all services (including spire's grafana/loki/prometheus/pid) to containers via local proxy devices.

To disable DNS challenge for a host (e.g. HTTP challenge), override `mine.caddy.globalConfig` to `""`.

### Service Access Patterns

**From tailnet devices** (laptop, phone): `pid.r6t.io` → Route53 CNAME → crown's tailscale IP → crown's caddy → service. Direct, encrypted.

**From LAN containers** (immich, miniflux): `pid.r6t.io` → dnsmasq wildcard → `192.168.6.10` (crown) → crown's caddy → proxy device → spire container. All local.

## Common Patterns

### Persistent Storage

Container filesystems are ephemeral — data persists via incus disk devices that bind-mount host directories into the container. Always use `shift: "true"` for UID/GID remapping in unprivileged containers.

**DynamicUser services require mounting to the `private` path, not the namespace path.** Many NixOS services (llama-cpp, open-webui, ntfy-sh, mollysocket) use systemd's `DynamicUser=true` with `StateDirectory` and/or `CacheDirectory`. Systemd stores data under a private directory and bind-mounts it into the service namespace at the well-known path:

| systemd directive | Private path (host-visible)    | Namespace path (service sees) |
| ----------------- | ------------------------------ | ----------------------------- |
| `StateDirectory`  | `/var/lib/private/{service}`   | `/var/lib/{service}`          |
| `CacheDirectory`  | `/var/cache/private/{service}` | `/var/cache/{service}`        |

If incus mounts host storage to the namespace path (e.g. `/var/lib/{service}`), the service fails at startup with `status=238/STATE_DIRECTORY` or `status=239/CACHE_DIRECTORY` because systemd finds a pre-existing public directory where it expects to create a private bind-mount.

The correct pattern for DynamicUser services:

1. In the container `.nix`, pre-create the private mount points:

```nix
systemd.tmpfiles.rules = [
  "d /var/lib/private 0700 root root -"
  "d /var/lib/private/{service} 0700 root root -"
  # If the service also uses CacheDirectory:
  "d /var/cache/private 0700 root root -"
  "d /var/cache/private/{service} 0700 root root -"
];
```

2. In the incus profile `.yaml`, mount to the private path:

```yaml
{service}-data:
  path: /var/lib/private/{service}
  shift: "true"
  source: /mnt/crownstore/app-storage/{name}
  type: disk
# If the service also uses CacheDirectory:
{service}-cache:
  path: /var/cache/private/{service}
  shift: "true"
  source: /mnt/crownstore/app-storage/{name}-cache
  type: disk
```

Services with static users (immich, jellyfin, audiobookshelf, PostgreSQL) do **not** use DynamicUser and should mount directly to `/var/lib/{service}`. Check the upstream NixOS module for `DynamicUser`, `StateDirectory`, or `CacheDirectory` to determine which pattern applies.

### Port Forwarding

App containers on crown expose ports to the host via incus proxy devices. Crown's caddy reverse-proxies to `http://localhost:{port}`. Define the proxy device in the profile YAML and the route in `caddy-routes.nix`.

### GPU Passthrough

For CUDA workloads (immich, llm), add a GPU device to the profile:

```yaml
gpu:
  gid: "303"
  gputype: physical
  pci: 0000:0c:00.0
  type: gpu
```

For **containers** (not VMs), `gputype: physical` passes GPU device nodes (`/dev/nvidia*`, `/dev/dri/*`) into the container. Multiple containers can share the same physical GPU simultaneously — VRAM is shared, not partitioned. The `pci:` filter selects which GPU when a host has multiple. Note that `physical` is the incus default when `gputype` is omitted.

If a CUDA crash inside one container wedges the GPU driver (kernel log shows `rpcRmApiFree_GSP: GspRmFree failed`), other containers may fail to get NVIDIA device nodes on next launch. Restart all GPU containers (or reboot the host) to recover.

### Tailscale Access

Containers that need to be reachable on the tailnet import the tailscale module:

```nix
mine.tailscale = {
  enable = true;
  ephemeral = true; # Auto-remove from tailnet on LXC stop
  extraUpFlags = [ "--accept-dns=false" ]; # Preserve local dnsmasq pattern
};
```

For containers that should auto-join the tailnet (e.g. exit nodes):

```nix
mine.tailscale.authKeyFile = "/etc/tailscale/auth-key";
```

The auth key file is bind-mounted from host storage via the incus profile. Use an ephemeral + reusable key from Tailscale admin. The `tailscale-set-hostname` service (centralized in the tailscale module) automatically ensures the node name matches the container's cloud-init hostname, preventing `-1` suffixes.

### Exit Nodes

Exit node containers (`tailnet-exit.nix`) auto-join the tailnet with `--advertise-exit-node --accept-routes --hostname={name}`. Each gets a dedicated physical NIC (named `exit0`-`exit3` via systemd.network.links PCI path pinning) for traffic isolation from app containers.

## Monitoring and Log Collection

### Architecture

```
Crown host Alloy
  ├── Host journald  ──→  loki.r6t.io (spire, via caddy on localhost)
  └── /var/log/incus-journals/*.json  ──→  loki.r6t.io

incus-log-collector service (crown)
  └── incus exec {name} -- journalctl --follow --output=json
      └── writes to /var/log/incus-journals/{name}.json per container

Spire (crown)
  ├── Grafana  ──  dashboards + OIDC via PocketID
  ├── Loki     ──  receives logs from crown's Alloy
  ├── Prometheus  ──  scrapes metrics
  └── PocketID  ──  OIDC provider for all services
```

Crown's host-level Alloy collects both host and container logs. Containers do NOT push to Loki directly — the `incus-log-collector` service on crown manages one `journalctl --follow` process per running container, writing JSON to `/var/log/incus-journals/`. Alloy tails these files and ships to Loki on spire over the tailnet.

### Nightly Rebuilds

The `incus-nightly-rebuild` NixOS module runs `containers/build.py --nightly` at 03:00. It queries incus for running instances, matches them to container `.nix` files (direct name match or via `instance_map.json`), and runs `nix build` for each. Nix's caching means unchanged containers complete instantly.

## Deployment Workflow

### Full rebuild (all containers)

```fish
# On crown
cd ~/git/nixos-r6t && git pull
nrs                                    # Rebuild NixOS, syncs incus profiles
python3 containers/build.py            # Build all images
python3 containers/relaunch.py         # Relaunch containers with newer images

# On saguaro
cd ~/git/nixos-r6t && git pull
sudo nixos-rebuild switch --flake '.#saguaro'
```

### Single container update

```fish
# On crown
python3 containers/build.py miniflux
python3 containers/relaunch.py miniflux
```

**Important:** `build.py` and `relaunch.py` only update the container image. They do **not** sync incus profiles. If you changed a `hosts/{host}/incus-instances/{name}.yaml`, you must run `nrs` first to push the updated profile into incus before relaunching — otherwise the container starts with the old profile.

```fish
# Profile change + image rebuild:
nrs                                    # Syncs updated YAML profiles into incus
python3 containers/build.py {name}    # Rebuild image (if .nix also changed)
python3 containers/relaunch.py {name} # Relaunch picks up new profile + image
```

If only the profile YAML changed (no `.nix` changes), `nrs` + `relaunch.py` is sufficient — no image rebuild needed.

## Quick Reference

| Task                        | Command                                                         |
| --------------------------- | --------------------------------------------------------------- |
| List buildable containers   | `python3 containers/build.py --list`                            |
| Build one container         | `python3 containers/build.py {name}`                            |
| Build all containers        | `python3 containers/build.py`                                   |
| Nightly mode                | `python3 containers/build.py --nightly`                         |
| Relaunch changed containers | `python3 containers/relaunch.py`                                |
| Relaunch specific           | `python3 containers/relaunch.py {name}`                         |
| Force relaunch all          | `python3 containers/relaunch.py --all`                          |
| Preview relaunch            | `python3 containers/relaunch.py --dry-run`                      |
| Launch new instance         | `incus launch {name} {name} --profile {name}`                   |
| Force cloud-init re-seed    | `incus exec {name} -- cloud-init clean && incus restart {name}` |
