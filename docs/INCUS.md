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
containers/build.py            Builds images via nix, imports into incus image store
    |
    v
hosts/{host}/incus-instances/
    {name}.yaml            Incus profile (networking, storage mounts, devices)
    seed/{name}.*          Cloud-init seed files (static IP, hostname)
```

Two hosts run incus:

- **crown** — primary compute server, runs most LXC containers and VMs
- **saguaro** — router, runs Home Assistant VM and the spire monitoring container

Images are built on crown and can be pushed to saguaro via `incus image copy local:<name> saguaro: --alias <name>`.

## Directory Structure

### Container Definitions: `containers/`

Every `.nix` file directly in `containers/` is a buildable LXC image. The flake auto-discovers them — drop a new file here and it becomes a build target.

```
containers/
    audiobookshelf.nix      Buildable image definitions
    miniflux.nix
    spire.nix
    ...
    lib/                    Shared base layers and add-ons (NOT buildable images)
        base.nix            Common LXC base: cloud-init, dnsmasq, packages, fish
        dns-overrides.nix   LAN DNS overrides for *.r6t.io resolution
        mullvad-dns.nix     Stubby DoT resolver via Mullvad (port 5353)
        nextdns.nix         NextDNS resolver (port 5353)
        wg-exit-node.nix    WireGuard + exit-node routing base
```

### Instance Profiles: `hosts/{host}/incus-instances/`

Incus profile YAML files define the runtime environment — how the container connects to the network, what host directories are mounted in, and what ports are exposed. These are the source of truth for incus configuration and are applied with `incus profile edit <name> < file.yaml`.

```
hosts/crown/incus-instances/
    audiobookshelf.yaml     Profile YAML for each instance
    miniflux.yaml
    ...
    seed/                   Cloud-init NoCloud seed files
        miniflux.meta-data
        miniflux.network-config
        miniflux.user-data

hosts/saguaro/incus-instances/
    haos.yaml               Home Assistant VM
    spire.yaml              Monitoring + auth container
    seed/
        spire.meta-data
        spire.network-config
        spire.user-data
```

### Build Tooling

- **`flake.nix`** — auto-generates `nix build .#<name>` and `nix build .#<name>-metadata` targets for every `containers/*.nix` file
- **`containers/build.py`** — builds images and imports them into incus. Supports `--list`, `--dry-run`, `--nightly`, and building specific containers by name
- **`hosts/crown/incus-instances/instance_map.json`** — maps incus instance names to container build targets when they differ (e.g. `mv-seattle` -> `tailnet-exit`)

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
- The base layer imports `./lib/dns-overrides.nix` automatically — this resolves `*.r6t.io` to the correct LAN IPs so containers can reach caddy reverse proxies
- `networking.hostName` must match the filename (without `.nix`)
- Persistent data directories should use conventional paths (`/var/lib/{service}`) — actual storage is bind-mounted by the incus profile

### Step 2: Build the image

```fish
# Build just this container
python3 containers/build.py {name}

# Or build manually
nix build .#{name}
nix build .#{name}-metadata
```

The builder produces two tarballs (rootfs + metadata) and imports them into the local incus image store with alias `{name}`.

### Step 3: Create the incus profile

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
    nictype: bridged # "bridged" for crown (br1), "physical" for dedicated NIC
    parent: br1 # br1 on crown, or enp0s13f0u1c2 on saguaro
    type: nic
  root:
    path: /
    pool: default # Required: "default" on crown, "kingston-pool" on saguaro
    type: disk # Inherited from default profile only if assigned — we use custom profiles exclusively
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
  # Add service-specific devices below:
  # Persistent storage (bind mounts from host):
  #   {name}-data:
  #     path: /var/lib/{service}    # Path inside container
  #     shift: "true"               # UID/GID remapping for unprivileged containers
  #     source: /mnt/crownstore/... # Path on host
  #     type: disk
  # Port forwarding (proxy devices):
  #   {name}-port:
  #     connect: tcp:127.0.0.1:8080  # Container-side address
  #     listen: tcp:0.0.0.0:8080     # Host-side listener
  #     type: proxy
  # GPU passthrough:
  #   gpu:
  #     gid: "303"
  #     gputype: physical
  #     pci: 0000:0c:00.0
  #     type: gpu
name: { name }
```

### Step 4: Create seed files

Create three files in `hosts/{host}/incus-instances/seed/`:

**`{name}.meta-data`**:

```
instance-id: {name}
local-hostname: {name}
```

**`{name}.network-config`** — assigns a static IP and gateway:

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

### Step 5: Launch the instance

```fish
# Create the profile
incus profile create {name}
incus profile edit {name} < hosts/{host}/incus-instances/{name}.yaml

# Launch from the image
incus launch {name} {name} --profile {name}

# Or if pushing to saguaro from crown:
incus image copy local:{name} saguaro: --alias {name}
# Then on saguaro:
incus launch {name} {name} --profile {name}
```

### Step 6: Update instance_map.json (if needed)

If the incus instance name differs from the container build target name (e.g. multiple instances from one image, or Docker-based instances), add a mapping to `hosts/crown/incus-instances/instance_map.json`:

```json
{
  "mv-seattle": "tailnet-exit",
  "pirate-ship": "docker"
}
```

This tells `containers/build.py --nightly` which image to rebuild for each running instance.

## Network Topology

All containers use static IPs on the 192.168.6.0/24 LAN. DHCP pool is 11-89; static assignments are outside this range.

### Gateway Routing

Most app containers don't route directly to the internet. They route through Mullvad WireGuard exit nodes (also LXC containers on crown) for privacy:

```
App container  -->  Exit node container (WireGuard)  -->  Saguaro (router)  -->  Internet
  .91-.104            .4-.7 (mv-*)                          .1
```

The gateway IP in each container's `network-config` determines which exit node it routes through.

### DNS Resolution

Every container runs a local dnsmasq instance on port 53 that:

1. Resolves `*.r6t.io` names to LAN IPs via `containers/lib/dns-overrides.nix` (so containers can reach caddy reverse proxies without hairpin NAT)
2. Forwards all other queries to an upstream resolver on port 5353 — either Mullvad DoT (`lib/mullvad-dns.nix`) or NextDNS (`lib/nextdns.nix`)

### Caddy Reverse Proxy

Services are accessed via `https://{service}.r6t.io` through caddy reverse proxies. There are two modes:

**Host mode (crown)**: Caddy runs on the host, not in a container. Routes are declared in nix via `mine.caddy.routes` in the host's `configuration.nix`. The Caddyfile is generated at build time. Each container exposes ports to the host via incus proxy devices, and caddy reverse-proxies to `http://localhost:{port}`.

To add a new route when creating a container on crown, add to `containers/lib/caddy-routes.nix`:

```nix
myapp = {
  "myapp.r6t.io" = { upstream = "http://localhost:8080"; };
};
```

Then add the container name to the `crownContainers` list in `hosts/crown/configuration.nix`.

And add a matching proxy device to the incus profile YAML:

```yaml
myapp-port:
  connect: tcp:127.0.0.1:8080
  listen: tcp:0.0.0.0:8080
  type: proxy
```

**Container mode (spire)**: Caddy runs inside the container with nix-generated routes, same as host mode. The only difference is the ACME env file is bind-mounted in via an incus disk device. This is used when the container manages its own TLS termination (e.g. spire on saguaro, which is on the tailnet and not behind a host-level reverse proxy).

```nix
mine.caddy = {
  enable = true;
  acmeEmail = "domains@r6t.io";
  acmeDnsConfig = ''
    acme_dns route53 { ... }
  '';
  environmentFile = "/etc/caddy/caddy.env";  # Bind-mounted by incus
  routes = allCaddyRoutes.spire;              # From containers/lib/caddy-routes.nix
};
```

Containers on the tailnet can also be accessed directly via their tailscale IPs.

## Common Patterns

### Persistent Storage

Container filesystems are ephemeral — data persists via incus disk devices that bind-mount host directories into the container. Always use `shift: "true"` for UID/GID remapping in unprivileged containers.

```yaml
# In the profile YAML
{name}-data:
  path: /var/lib/{service}
  shift: "true"
  source: /mnt/crownstore/app-storage/{name}
  type: disk
```

### Port Forwarding

Containers listen on localhost inside the container. Proxy devices forward traffic from the host's bridge IP:

```yaml
{name}-port:
  connect: tcp:127.0.0.1:8080
  listen: tcp:0.0.0.0:8080
  type: proxy
```

### GPU Passthrough

For CUDA workloads (immich, llm):

```yaml
gpu:
  gid: "303"
  gputype: physical
  pci: 0000:0c:00.0
  type: gpu
```

### Tailscale Access

Containers that need to be reachable on the tailnet import the tailscale module. The module marks `tailscale0` as a trusted interface, so all ports are open over the tailnet without explicit firewall rules.

```nix
imports = [ ../modules/nixos/tailscale/default.nix ];
mine.tailscale.enable = true;
```

## Nightly Rebuilds

The `incus-nightly-rebuild` NixOS module runs `containers/build.py --nightly` on a timer. It:

1. Queries incus for running instances
2. Matches them to container `.nix` files (direct name match or via `instance_map.json`)
3. Runs `nix build` for each — nix's caching means unchanged containers complete instantly
4. Imports updated images into the incus store

This keeps the image store current after `flake update` or module changes, so that relaunching a container always uses the latest build.

## Quick Reference

| Task                      | Command                                                                |
| ------------------------- | ---------------------------------------------------------------------- |
| List buildable containers | `python3 containers/build.py --list`                                   |
| Build one container       | `python3 containers/build.py {name}`                                   |
| Build all containers      | `python3 containers/build.py`                                          |
| Dry run                   | `python3 containers/build.py --dry-run {name}`                         |
| Nightly mode              | `python3 containers/build.py --nightly`                                |
| Apply a profile           | `incus profile edit {name} < hosts/{host}/incus-instances/{name}.yaml` |
| Launch instance           | `incus launch {name} {name} --profile {name}`                          |
| Force cloud-init re-seed  | `incus exec {name} -- cloud-init clean && incus restart {name}`        |
| Push image to saguaro     | `incus image copy local:{name} saguaro: --alias {name}`                |
