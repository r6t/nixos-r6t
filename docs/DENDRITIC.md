# Dendritic Migration

This document tracks the compatibility contract for the `dendretic` branch while
the flake is refactored toward a dendritic, flake-parts-oriented structure.

The first rule is stability of public outputs. Internal files may move, but the
flake attributes below should remain available unless an intentional migration is
documented first.

## Baseline Public Contract

### NixOS Hosts

These host outputs are the operational entry points for system rebuilds:

- `nixosConfigurations.barrel`
- `nixosConfigurations.crown`
- `nixosConfigurations.goldenball`
- `nixosConfigurations.mountainball`
- `nixosConfigurations.saguaro`

### Home Manager Modules

These are exported for downstream flakes, including `~/git/nix-work-r6t`:

- `homeManagerModules.default`
- `homeManagerModules.alacritty`
- `homeManagerModules.atuin`
- `homeManagerModules.fish`
- `homeManagerModules.git`
- `homeManagerModules.nixvim`
- `homeManagerModules.zellij`

Downstream standalone Home Manager users currently provide:

- `userConfig.username`
- `userConfig.homeDirectory`
- `isNixOS = false`

This is the stable compatibility API for downstream flakes. Internal module
paths may change, but these exported names should continue to work. Downstream
flakes should import only the modules they intend to configure, then enable them
through the existing `mine.home.*` options.

`homeManagerModules.default` is an additive aggregate of the portable modules
listed above. It also imports the upstream `nixvim.homeModules.nixvim`
dependency needed by `homeManagerModules.nixvim`, but does not enable any
features. Prefer explicit per-module imports for narrow downstream flakes; use
`default` when importing the full portable option surface is more convenient.

Downstreams that import `homeManagerModules.nixvim` directly should also import
their own `nixvim.homeModules.nixvim`, as `~/git/nix-work-r6t` does today.

Example standalone Home Manager usage:

```nix
{
  extraSpecialArgs = {
    userConfig = {
      username = "example";
      homeDirectory = "/home/example";
    };
    isNixOS = false;
  };

  modules = [
    nixos-r6t.homeManagerModules.fish
    nixos-r6t.homeManagerModules.git
    ({ ... }: {
      mine.home.fish.enable = true;
      mine.home.git.enable = true;
    })
  ];
}
```

### NixOS Modules

These are exported for downstream NixOS flakes:

- `nixosModules.default`

`nixosModules.default` points at `modules/default.nix`, the compatibility
aggregate for downstream NixOS users. It exposes the `mine.*` option surface but
does not enable features by itself. Repo-owned hosts do not import this
aggregate; they compose profile and host modules through `modules.nixos.<host>`.

### NixOS Host Factory

These helper exports build NixOS systems without changing the operational
`nixosConfigurations.<host>` rebuild entry points:

- `lib.mkNixosHost`
- `lib.mkRegisteredNixosHost`

`lib.mkNixosHost { modules = [ ... ]; }` is the generic factory. It uses the
same default `specialArgs` as this repository's host configurations unless a
caller passes explicit `specialArgs`.

`lib.mkRegisteredNixosHost "mountainball"` is the repo-local convenience wrapper
used by `nixosConfigurations.*`. It consumes `modules.nixos.<host>` entries.

### Dendritic Module Registry

These `modules` outputs are the branch's first dendritic registry layer. They
store lower-level modules by class while compatibility exports continue to serve
existing consumers:

The stable external API remains `nixosConfigurations.*`, `homeManagerModules.*`,
`nixosModules.default`, `packages.*`, and `checks.*`. Treat most
`modules.nixos.<profile>` and `modules.nixos.<host>` entries as repo-internal
composition points unless this document explicitly promotes one to downstream
API.

- `modules.homeManager.alacritty`
- `modules.homeManager.atuin`
- `modules.homeManager.fish`
- `modules.homeManager.git`
- `modules.homeManager.nixvim`
- `modules.homeManager.zellij`
- `modules.nixos.barrel`
- `modules.nixos.booted-host`
- `modules.nixos.cgrouped-nix-builds`
- `modules.nixos.crown`
- `modules.nixos.default`
- `modules.nixos.gaming-host`
- `modules.nixos.goldenball`
- `modules.nixos.incus-host`
- `modules.nixos.infra-host`
- `modules.nixos.infra-networkd-journal`
- `modules.nixos.kde-workstation`
- `modules.nixos.laptop-workstation`
- `modules.nixos.monitoring-agent`
- `modules.nixos.mountainball`
- `modules.nixos.nfs-photos-client`
- `modules.nixos.nfs-pictures-export`
- `modules.nixos.nix-build-throttle`
- `modules.nixos.nvidia-container-host`
- `modules.nixos.office-desk`
- `modules.nixos.r6t-base`
- `modules.nixos.r6t-home-core`
- `modules.nixos.r6t-home-shell`
- `modules.nixos.r6t-system-core`
- `modules.nixos.router`
- `modules.nixos.saguaro`
- `modules.nixos.sops-host`
- `modules.nixos.static-lan-host`
- `modules.nixos.sync-host`
- `modules.nixos.tailnet-host`
- `modules.nixos.thunderbolt-host`
- `modules.nixos.zfs-host`

Compatibility exports should alias through this registry rather than importing
implementation files directly:

- `homeManagerModules.*` aliases `modules.homeManager.*`
- `nixosModules.default` aliases `modules.nixos.default`

`nixosConfigurations.*` also consumes the host-specific registry entries under
`modules.nixos.<host>`. Those host modules currently wrap the existing files in
`hosts/<host>/configuration.nix`; the host file contents have not been moved.
Host files may directly import host-local implementation modules during the
migration, but they should not import the global compatibility aggregate.

Host aspect registrations are colocated with their host directories. Each
`hosts/<host>/flake-module.nix` defines the matching `modules.nixos.<host>`
registry entry and imports `hosts/<host>/configuration.nix`.

The base NixOS module registry entry is colocated with the module tree:
`modules/flake-module.nix` defines `modules.nixos.default` as
`modules/default.nix`.

`modules/default.nix` is the compatibility aggregate for the legacy `mine.*`
option surface and backs `nixosModules.default`. It intentionally lists each
`flatpak`, `home`, and `nixos` leaf module explicitly instead of auto-discovering
directories, so new leaf modules must be registered deliberately. It is not part
of repo-owned host composition.

During migration, do not add new `mine.*.enable` activation hooks. Direct
imports and profiles should activate behavior. Keep existing `mine.*` options
only for compatibility consumers or for real knobs that still need a custom
namespace; design a replacement namespace deliberately if the old name becomes
misleading.

Portable Home Manager aspect registrations are colocated with their feature
directories. Each `modules/home/<name>/flake-module.nix` defines the matching
`modules.homeManager.<name>` registry entry, while the actual Home Manager
module remains `modules/home/<name>/default.nix`.

Profile aspects live under `modules/profiles/<name>/flake-module.nix`. These
are NixOS-class aspects that compose existing lower-level modules with direct
leaf imports and, where a leaf has not yet migrated, `lib.mkDefault` activation
values. They provide host-file reduction without yet rewriting every leaf module
away from `mine.*.enable` gates.

Current profile aspects:

- `modules.nixos.booted-host` enables the standard bootloader module for hosts
  that boot from this flake.
- `modules.nixos.cgrouped-nix-builds` enables Nix build cgroup accounting for
  hosts where this was already configured directly.
- `modules.nixos.gaming-host` enables shared gaming/runtime defaults: unfree
  packages, NetworkManager, sound, and Steam.
- `modules.nixos.incus-host` enables Incus, defaulting `mine.incus.profileDir`
  to `hosts/<hostname>/incus-instances`, and enables nftables for Incus hosts.
- `modules.nixos.infra-host` composes `cgrouped-nix-builds`,
  `infra-networkd-journal`, and `nix-build-throttle` for headless infra hosts.
- `modules.nixos.infra-networkd-journal` caps journald size and disables
  `systemd-networkd-wait-online` for networkd-managed infra hosts.
- `modules.nixos.kde-workstation` enables the common KDE workstation desktop
  stack: KDE, NetworkManager, Flatpak desktop apps, shared desktop Home Manager
  apps, fonts, sound, printing, supporting tools, and the nixpkgs allowUnfree /
  temporary Electron exceptions needed by those apps.
- `modules.nixos.laptop-workstation` enables laptop defaults shared by
  `mountainball` and `goldenball`: a short systemd-boot generation limit and
  disabled fingerprint service.
- `modules.nixos.monitoring-agent` enables Alloy and Prometheus node exporter.
- `modules.nixos.nfs-photos-client` mounts crown's curated photo export on
  workstation clients.
- `modules.nixos.nfs-pictures-export` defines crown's curated Pictures NFS
  export and its storage mount ordering.
- `modules.nixos.nix-build-throttle` caps `nix-daemon` CPU to `800%` on hosts
  where long builds should not consume the whole machine.
- `modules.nixos.nvidia-container-host` enables NVIDIA/CUDA host support for
  container GPU passthrough without installing the full CUDA toolkit.
- `modules.nixos.office-desk` enables USB4 SFP+ dock support for systems that use
  the physical office desk Thunderbolt dock. This currently applies to
  `mountainball` and `goldenball` only, and imports `thunderbolt-host`.
- `modules.nixos.r6t-base` composes `booted-host`, `r6t-system-core`, and
  `tailnet-host` for normal flake-managed hosts.
- `modules.nixos.r6t-home-core` enables the shared portable Home Manager core:
  home-manager, atuin, fish, git, nixvim, and ssh.
- `modules.nixos.r6t-home-shell` extends `r6t-home-core` with zellij. This is
  the preferred name instead of `r6t-home-cli` because the profile describes an
  interactive shell environment rather than a generic CLI role.
- `modules.nixos.r6t-system-core` enables conservative fleet defaults: fwupd,
  fzf, iperf, localization, nix, ssh, user, common system packages, system fish
  shell support, fail2ban SSH hardening, and the shared time zone.
- `modules.nixos.router` composes `monitoring-agent`, direct-imports the Home
  Router implementation, and enables router-specific Alloy syslog ingestion
  defaults while leaving interface names and reservations host-local.
- `modules.nixos.sops-host` imports upstream `sops-nix`, direct-imports the
  local SOPS configuration, and leaves host-specific secret files and age key
  paths host-local.
- `modules.nixos.static-lan-host` enables networkd, LAN DNS, the default LAN
  gateway address, and resolved settings for static LAN servers.
- `modules.nixos.sync-host` enables SSHFS and Syncthing for hosts that already
  share the sync stack.
- `modules.nixos.tailnet-host` enables Tailscale for normal hosts. Container
  image modules still use the legacy `mine.tailscale.enable` flag because their
  DNS override behavior depends on that option value.
- `modules.nixos.thunderbolt-host` enables Bolt for Thunderbolt/USB4-capable
  hosts.
- `modules.nixos.zfs-host` enables ZFS filesystem support.

`modules.nixos.r6t-base` owns behavior that used to live in the catch-all
`modules/nixos/nixos-r6t-baseline/default.nix` module. The split files are kept
inside the profile directory:

- `modules/profiles/r6t-base/ssh-hardening.nix`
- `modules/profiles/r6t-base/system-packages.nix`
- `modules/profiles/r6t-base/system-shell.nix`

`mine.nixos-r6t-baseline.enable` is legacy compatibility only. Hosts should use
`r6t-system-core` or `r6t-base` instead. Do not add new behavior there.

Direct-import migration is underway for profile- and host-owned leaves. Migrated
leaves expose a direct `config.nix` implementation imported by profiles or host
configs, while their `default.nix` files keep old `mine.*.enable` wrappers for
compatibility consumers. Leaves with custom non-enable options may split those
declarations into `options.nix`, imported by both the wrapper and direct
profiles. This is the preferred migration pattern for removing enable hooks
without breaking old imports. Current direct-import leaves include bootloader,
Nix, SSH, user, fwupd, fzf, iperf, localization, NetworkManager, sound,
Bluetooth, czkawka, direnv, fonts, npm, printing, v4l-utils, zola, Bolt,
Prometheus node exporter, SSHFS, Syncthing, USB4 SFP support, desktop Flatpak
apps, browsers, darktable, KDE apps, the KDE desktop, Steam, Tailscale host
configuration, Home Router, SOPS host configuration, MakeMKV, Docker, Incus log
collection, ddc-i2c, Mullvad, Pinchflat, rdfind, OBS Studio, Orca Slicer, and
virt-viewer.

SOPS is the semantic exception to simple `enable` migration. `mine.sops.enable`
is now legacy wrapper activation only. Modules that conditionally add optional
`sops.secrets` entries should check `mine.sops.available`, which is set by the
active SOPS configuration and therefore models whether this host has `sops-nix`
configured. Profiles should import `modules.nixos.sops-host`; hosts should keep
only path-like SOPS facts such as `mine.sops.defaultSopsFile` and
`mine.sops.ageKeyFile` host-local.

### Leaf Migration Guardrails

Treat `config.nix` splits as implementation movement, not as new public API.

- Only split a leaf when direct import of its ungated behavior is equivalent to
  enabling the existing `mine.<leaf>.enable` option.
- Keep `modules/nixos/<leaf>/default.nix` in `modules/default.nix` while the
  legacy `mine.*` option surface exists. The wrapper owns the legacy enable gate
  and should continue to gate `import ./config.nix` with `lib.mkIf`.
- If `config.nix` still reads custom `mine.*` knobs, move those option
  declarations to `options.nix` and import it from both the wrapper and any
  direct-importing profile or host module.
- Helper-generated wrappers such as `mkHomePackageModule` and `mkFlatpakModule`
  should receive `optionsModule = ./options.nix`, not `import ./options.nix`, so
  profile path imports and wrapper imports de-duplicate as the same module.
- Put only active feature configuration in `config.nix`. Do not declare
  `mine.*` options, inspect `mine.<leaf>.enable`, or add a second enable gate
  there; profiles import `config.nix` because they want the feature enabled.
- Preserve non-enable compatibility options in `options.nix` or the wrapper, and
  pass only the existing implementation inputs (`config`, `inputs`, `lib`,
  `pkgs`, and so on) through to `config.nix` as needed.
- Profiles should direct-import `../../nixos/<leaf>/options.nix` if needed and
  `../../nixos/<leaf>/config.nix` for migrated leaves, or compose another
  profile via `inputs.self.modules.nixos.<profile>`. Do not import a leaf
  `default.nix` from a profile just to toggle an enable option.
- Host configs may direct-import migrated leaf `config.nix` files for
  host-specific features that are not reusable profile behavior.
- Once a feature is direct-imported by a profile or host, `mine.<leaf>.enable =
false` no longer disables it. Remove stale false-hook tombstones rather than
  keeping misleading preferences. Keep explicit `enable = false` only when it is
  a real downstream service/module setting with behavior.
- Delete empty no-op compatibility modules instead of preserving inert option
  surface. Legacy wrappers are kept only when they still enable real behavior or
  preserve a compatibility contract.
- Do not add one `modules.nixos.<leaf>` registry entry per migrated leaf unless
  that leaf is intentionally becoming reusable module API. Prefer merging
  non-distinct lower-level modules under profile names.
- Keep host-specific facts host-local: hardware imports, interface names,
  addresses, mounts, secrets, and one-off service data should not become
  profiles without at least two consumers or a documented replacement-host
  story.
- Update the current direct-import leaf list above and run no-build eval checks
  before considering a pass complete.

No planned profile name should be added until it has a clear reusable role or a
clear future replacement-host story.

`flake/modules.nix` remains as the deliberate registration list for these
feature-owned flake-parts modules. It groups host, portable Home Manager, and
profile aspect names, then maps those names to colocated `flake-module.nix`
files. It should not own registry values directly unless there is no better
feature directory for the value yet.

This registry is intentionally deliberate. Add new entries only when they are
meant to become reusable module API, not just because a file exists in
`modules/`.

### Deferred Areas

Hold these areas for focused follow-up passes rather than mixing them into small
leaf migrations:

- Nixvim and `homeManagerModules.nixvim`, because downstream standalone Home
  Manager compatibility and upstream nixvim imports need a dedicated pass.
- Incus/LXC image and runtime modules, because container build attrs, profile
  paths, and runtime mapping files are operational contracts.

### Linux Packages

The package contract is currently Linux-only under `packages.x86_64-linux`.

Package output registration is now colocated with package owners:

- `containers/flake-module/default.nix` discovers direct `containers/*.nix`
  image definitions and defines the container image and metadata package outputs.
- `pkgs/rocmfp4-llama/flake-module.nix` defines
  `packages.x86_64-linux.rocmfp4-llama`.
- `flake/packages.nix` is the import list for package-output feature modules.

Custom package outputs:

- `packages.x86_64-linux.rocmfp4-llama`

Container image outputs:

- `packages.x86_64-linux.audiobookshelf`
- `packages.x86_64-linux.audiobookshelf-metadata`
- `packages.x86_64-linux.changedetection`
- `packages.x86_64-linux.changedetection-metadata`
- `packages.x86_64-linux.docker`
- `packages.x86_64-linux.docker-metadata`
- `packages.x86_64-linux.hermes`
- `packages.x86_64-linux.hermes-metadata`
- `packages.x86_64-linux.immich`
- `packages.x86_64-linux.immich-metadata`
- `packages.x86_64-linux.jellyfin`
- `packages.x86_64-linux.jellyfin-metadata`
- `packages.x86_64-linux.llm`
- `packages.x86_64-linux.llm-metadata`
- `packages.x86_64-linux.miniflux`
- `packages.x86_64-linux.miniflux-metadata`
- `packages.x86_64-linux.ntfy`
- `packages.x86_64-linux.ntfy-metadata`
- `packages.x86_64-linux.searxng`
- `packages.x86_64-linux.searxng-metadata`
- `packages.x86_64-linux.spire`
- `packages.x86_64-linux.spire-metadata`
- `packages.x86_64-linux.tailnet-exit`
- `packages.x86_64-linux.tailnet-exit-metadata`

### Checks

The current check output is Linux-only:

- `checks.x86_64-linux.pre-commit-check`

## Operational Compatibility

### Incus Image Builds

The Incus image workflow should remain stable while the flake internals change:

- Every `containers/*.nix` file remains a buildable image definition.
- `containers/lib/` remains shared support code, not buildable images.
- `nix build .#<container>` remains valid for every container image.
- `nix build .#<container>-metadata` remains valid for every container metadata output.
- `containers/build.py --list` should continue to discover container names from `containers/*.nix`.
- `containers/build.py --nightly` should continue to map running instances through `hosts/crown/incus-instances/instance_map.json`.
- `containers/relaunch.py` should continue to resolve per-host mappings from `hosts/<hostname>/incus-instances/instance_map.json`.

### Incus Runtime Profiles

The dendritic migration should not initially redesign runtime profiles:

- `hosts/crown/incus-instances/*.yaml` remains the source of crown profile state.
- `hosts/crown/incus-instances/seed/*` remains the source of crown NoCloud seed files.
- `mine.incus.profileDir` remains pointed at the host profile directory.
- `mine.incus-nightly-rebuild.flakePath` remains the operational flake checkout path.
- `mine.wg-metrics.instanceMapFile` remains pointed at the crown instance map.

## Compatibility Policy

- Prefer additive exports during migration.
- Do not rename or remove the baseline outputs above without a documented transition.
- Keep downstream compatibility through `homeManagerModules.*` even if dendritic `flake.modules.*` exports are added.
- Keep Incus image attr names stable even if image generation moves out of `flake.nix`.
- Keep Incus runtime profiles out of package-output migration; they remain host-specific operational state.

## No-Build Validation Commands

These commands evaluate output names without building or activating anything:

```fish
nix eval --json .#nixosConfigurations --apply builtins.attrNames
nix eval --json .#lib --apply builtins.attrNames
nix eval --json .#modules --apply builtins.attrNames
nix eval --json .#modules.homeManager --apply builtins.attrNames
nix eval --json .#modules.nixos --apply builtins.attrNames
nix eval --json .#nixosModules --apply builtins.attrNames
nix eval --json .#homeManagerModules --apply builtins.attrNames
nix eval --json .#packages.x86_64-linux --apply builtins.attrNames
nix eval --json .#checks.x86_64-linux --apply builtins.attrNames
```

After a leaf-migration pass, also force every registered NixOS host to evaluate
its system toplevel derivation path without building it:

```fish
for host in barrel crown goldenball mountainball saguaro
    nix eval --raw ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath"
end
```

Humans can also check container discovery without building:

```fish
python3 containers/build.py --list
```

Agents must not run `containers/build.py` under this repository's instructions.
