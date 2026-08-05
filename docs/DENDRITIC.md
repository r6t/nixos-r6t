# Dendritic Flake Structure

This flake uses small, colocated `flake-module.nix` entrypoints to register
profile, Home Manager, and package outputs. Real host and container inventory
lives in a private wrapper flake.

## Public Contract

Stable external outputs:

- `modules.nixos.*`: primary dendritic NixOS module/profile API
- `homeManagerModules.{default,alacritty,atuin,fish,git,nixvim,zellij}`
- `nixosModules.default`: conventional compatibility wrapper
- `checks.x86_64-linux.pre-commit-check`
- `lib.mkNixosHost`

Concrete `nixosConfigurations` are intentionally private. Downstream Home
and work flakes should compose host systems from `modules.nixos.*`, then add
their own private host facts. Downstream standalone Home Manager users should
import only the portable `homeManagerModules.*` they need, then enable features
through `mine.home.*` options.

`modules.nixos.*` is the supported dendritic API for this repo. It includes both
leaf modules and profile modules registered by colocated `flake-module.nix`
files. Prefer it for flakes that already consume `nixos-r6t` as a flake input.

`nixosModules.default` is compatibility-only. It imports `modules/default.nix`,
which exposes the legacy `mine.*` option surface for downstream NixOS users. It
does not enable repo features by itself. Private and work flakes should prefer
`modules.nixos.*` unless they specifically need the legacy wrapper.

## Registration

`flake/modules.nix` discovers immediate child directories with a
`flake-module.nix` under:

- `modules/home/`
- `modules/profiles/`

`flake/packages.nix` discovers immediate `pkgs/*/flake-module.nix` package
modules.

This is intentional auto-discovery: adding a plain directory does nothing;
adding `flake-module.nix` opts that directory into flake outputs.

## Private Host Composition

Private hosts import public profiles from `nixos-r6t.modules.nixos.*` and then
add private host files:

- reusable profiles from `nixos-r6t.modules.nixos.*`
- `hosts/<host>/configuration.nix` in the private flake

Keep host facts in host configs:

- hardware imports
- hostnames and host IDs
- interface names, addresses, gateways, and bridges
- mount UUIDs, key files, and storage ordering
- SOPS file/key paths
- Incus profile directories and runtime mapping paths
- concrete NFS mounts/exports
- host-specific GPU, LLM, firewall, and service tuning

## Profiles

Profiles live under `modules/profiles/<name>/flake-module.nix`. They should model
reusable behavior, not one-off host facts.

Current profile roles:

- `r6t-booted-system`: bootloader plus fleet system defaults.
- `r6t-base`: `r6t-booted-system` plus Tailscale for normal flake-managed hosts.
- `r6t-system-core`: conservative fleet defaults: Nix, SSH, user, locale,
  packages, shell, time zone, fwupd, fzf, iperf, and SSH hardening.
- `r6t-home-core`: Home Manager, atuin, fish, git, nixvim, and ssh.
- `r6t-home-shell`: `r6t-home-core` plus zellij.
- `desktop-basics`: NetworkManager, sound, and unfree package policy.
- `kde-desktop`: KDE, Bluetooth, fonts, printing, and common desktop device
  support.
- `r6t-desktop-app-suite`: personal desktop Flatpak/Home Manager app set and
  supporting desktop tools.
- `kde-workstation`: `kde-desktop` plus `r6t-desktop-app-suite`.
- `gaming-host`: `desktop-basics` plus Steam.
- `laptop-workstation`: laptop defaults shared by mobile workstations.
- `office-desk`: Thunderbolt/Bolt support.
- `infra-host`: headless infra defaults: cgrouped Nix builds, journald/networkd
  tuning, and Nix daemon CPU throttling.
- `static-lan-host`: networkd and resolved defaults for static LAN servers.
- `incus-host`: Incus host support and nftables.
- `nfs-host`: NFS implementation; hosts own concrete mounts/exports.
- `nvidia-container-host`: NVIDIA/CUDA host support for container GPU passthrough.
- `monitoring-agent`: Alloy and Prometheus node exporter.
- `router`: Home Router implementation plus router monitoring defaults.
- `sops-host`: upstream `sops-nix` plus local SOPS configuration.
- `sync-host`: SSHFS and Syncthing.
- `tailnet-host`: Tailscale for normal hosts.
- `thunderbolt-host`: Bolt.
- `zfs-host`: ZFS filesystem support.

Tiny profiles such as `cgrouped-nix-builds`, `infra-networkd-journal`, and
`nix-build-throttle` remain separate because hosts compose them independently.

## Leaf Modules

Migrated leaves use this shape:

- `options.nix`: reusable option declarations.
- `config.nix`: active implementation, with no legacy `mine.<leaf>.enable` gate.
- `default.nix`: compatibility wrapper that preserves old `mine.*.enable` usage.

Profiles and private hosts direct-import `options.nix` and `config.nix`. They
should not import a leaf `default.nix` just to turn on an enable option.

Once a feature is direct-imported, `mine.<leaf>.enable = false` no longer
disables it. Remove stale false-hook tombstones instead of keeping misleading
preferences.

`modules/default.nix` deliberately lists legacy flatpak, Home Manager, and NixOS
leaf wrappers. Keep entries there while they preserve downstream compatibility.

## Private Containers And Packages

Incus image definitions and runtime profiles are private because they encode
service inventory, bind mounts, domains, LAN layout, and passthrough devices.

Custom public packages can use `pkgs/<name>/flake-module.nix`. Hardware- or
host-specific packages belong in the private wrapper flake.

## Compatibility Rules

- Preserve the public outputs listed above unless a migration is documented first.
- Keep concrete `nixosConfigurations.<host>` in the private wrapper flake.
- Keep `homeManagerModules.*` stable for downstream flakes.
- Keep host-specific facts out of reusable profiles.
- Avoid new `mine.*.enable` activation hooks for repo-owned composition.
- Delete empty/no-op modules instead of preserving inert option surface.
- Do not genericize measured GPU/LLM tuning when it belongs in private
  host/container-local configuration.

## Validation

Use no-build checks for flake structure changes:

```fish
./format.fish
git diff --check
nix eval --json .#nixosConfigurations --apply builtins.attrNames
nix eval --json .#modules.nixos --apply builtins.attrNames
nix eval --json .#homeManagerModules --apply builtins.attrNames
```

Agents must not build or activate systems.
