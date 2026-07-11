# Incus LXC Containers

This flake builds NixOS LXC images and manages Incus runtime profiles for the
Incus hosts in `hosts/`.

## Contracts

- Every `.nix` file directly under `containers/` is a public image target:
  `.#<name>` and `.#<name>-metadata`.
- `containers/lib/` is shared implementation, not buildable output surface.
- Image packages use native NixOS outputs: `system.build.images.lxc` and
  `system.build.images.lxc-metadata`.
- Runtime state lives under `hosts/<host>/incus-instances/` as profile YAML,
  seed files, and optional `instance_map.json`.
- `mine.incus.profileDir` is host-owned because profiles reference checkout-path
  seed files.
- LXCs are cattle. Persistent data must be host bind mounts in Incus profiles;
  the container rootfs is disposable.

Incus hosts:

- `crown`: primary LXC host.
- `saguaro`: router host; currently Home Assistant OS VM only.

## Files

- `containers/*.nix`: image definitions.
- `containers/lib/base.nix`: common LXC base: cloud-init, dnsmasq, packages,
  fish, DNS override wiring.
- `containers/lib/{mullvad-dns,nextdns}.nix`: upstream DNS resolvers.
- `containers/lib/wg-exit-node.nix`: WireGuard/Tailscale exit-node base.
- `containers/lib/caddy-routes.nix`: single caddy route source for services.
- `containers/flake-module/default.nix`: package output generation.
- `containers/build.py`: builds/imports image aliases into Incus.
- `containers/relaunch.py`: stop/delete/launches running containers when image
  aliases changed.
- `hosts/<host>/incus-instances/*.yaml`: declarative Incus profiles.
- `hosts/<host>/incus-instances/seed/*`: NoCloud seed data.
- `hosts/<host>/incus-instances/instance_map.json`: instance name to image alias
  mapping when they differ.

## Profile Sync

`incus-profile-sync` runs from the Incus host configuration when
`mine.incus.profileDir` is set.

- Applies YAML directly from the mutable checkout path.
- Uses a Nix store copy only as a systemd restart trigger.
- Creates or overwrites live profiles to match YAML.
- Prunes retired non-default profiles; if a profile is still in use, deletion
  warns and continues.

Changing only profile YAML requires a host rebuild/switch before relaunching the
container. Changing only `containers/<name>.nix` requires an image rebuild and
relaunch.

## Creating A Container

1. Add `containers/<name>.nix`.
2. Import `./lib/base.nix` and one DNS resolver unless the role needs a custom
   base.
3. Set `networking.hostName = "<name>"` for single-instance images.
4. Add service modules. Prefer direct `options.nix` plus `config.nix` imports
   when the leaf has been split.
5. Open only the ports needed on LAN. Tailnet containers get trusted
   `tailscale0` handling from the Tailscale module.
6. If exposed through caddy, add routes to `containers/lib/caddy-routes.nix` and
   list the route group in crown's `crownContainers`.
7. Add `hosts/<host>/incus-instances/<instance>.yaml` and matching seed files.
8. If the instance name differs from the image alias, add it to
   `instance_map.json`.

Minimal image shape:

```nix
{ ... }:

{
  imports = [
    ./lib/base.nix
    ./lib/mullvad-dns.nix
  ];

  networking.hostName = "myapp";
}
```

Minimal profile shape:

```yaml
config:
  security.nesting: "true"
description: myapp
devices:
  eth0:
    name: eth0
    nictype: bridged
    parent: br1
    type: nic
  root:
    path: /
    pool: default
    type: disk
  seed-meta-data:
    path: /var/lib/cloud/seed/nocloud/meta-data
    source: /home/r6t/git/nixos-r6t/hosts/crown/incus-instances/seed/myapp.meta-data
    type: disk
name: myapp
```

Seed files are standard NoCloud `meta-data`, `network-config`, and `user-data`.
Use static LAN addresses outside the DHCP pool (`192.168.6.11-89`).

## Build And Relaunch

Human commands:

```fish
python3 containers/build.py --list
python3 containers/build.py myapp
python3 containers/relaunch.py myapp
```

Useful flags:

- `containers/build.py --dry-run`
- `containers/build.py --nightly`: crown-oriented; matches running instances via
  `hosts/crown/incus-instances/instance_map.json`.
- `containers/relaunch.py --dry-run`
- `containers/relaunch.py --all`

`relaunch.py` reads `hosts/(hostname)/incus-instances/instance_map.json`, checks
image fingerprints, verifies the matching profile exists, then stop/delete/launches
the instance. State survives only through host bind mounts.

Agents must not run `containers/build.py`, `containers/relaunch.py`, Nix builds,
or NixOS activations.

## Networking And DNS

- App containers use crown's `br1` bridge.
- Exit-node containers use dedicated physical NICs named `exit0`-`exit3` on
  crown, pinned by PCI path.
- Containers run local dnsmasq on port 53.
- LAN containers resolve `*.r6t.io` to crown caddy at `192.168.6.10` via
  `dns-overrides.nix`.
- Tailscale-enabled containers bypass LAN overrides and use Tailscale DNS for
  tailnet paths.
- Tailscale MagicDNS uses split DNS for `*.ts.net` through `100.100.100.100`.

Caddy runs on crown and routes to containers through local Incus proxy devices.
The route source is `containers/lib/caddy-routes.nix`; crown selects active route
groups in `hosts/crown/configuration.nix`.

## Storage

Use profile disk devices for persistent state:

```yaml
myapp-data:
  path: /var/lib/myapp
  shift: "true"
  source: /mnt/crownstore/app-storage/myapp
  type: disk
```

For services with `DynamicUser=true`, mount the host storage to systemd's private
path, not the public namespace path:

- `StateDirectory=myapp`: mount `/var/lib/private/myapp`.
- `CacheDirectory=myapp`: mount `/var/cache/private/myapp`.

Pre-create private mount points with `systemd.tmpfiles.rules` inside the image.
Static-user services such as PostgreSQL, Immich, Jellyfin, and Audiobookshelf can
mount directly to `/var/lib/<service>`.

## GPU Passthrough

Crown's active `llm` container uses NVIDIA TensorRT-LLM. Prefer stable
vendor/product filters over PCI BDFs unless two identical GPUs need
disambiguation:

```yaml
config:
  nvidia.driver.capabilities: all
  nvidia.runtime: "true"
devices:
  gpu:
    gid: "303"
    gputype: physical
    vendorid: "10de"
    productid: "2d04"
    type: gpu
```

For ROCm containers, also pass `/dev/kfd`:

```yaml
kfd:
  path: /dev/kfd
  source: /dev/kfd
  type: unix-char
```

ROCm needs `/dev/kfd` plus the filtered render node. Vulkan only needs render
nodes, but the image must enable `hardware.graphics.enable` so the Vulkan ICDs
exist under `/run/opengl-driver`.

## Monitoring

Crown collects container logs centrally:

- `incus-log-collector` runs `incus exec <name> -- journalctl --lines=0 --follow
--output=json` per running container.
- Logs are written to `/var/log/incus-journals/<name>.json`.
- Crown Alloy tails those files and ships to Loki on `spire`.

`spire` hosts Grafana, Loki, Prometheus, and PocketID.
