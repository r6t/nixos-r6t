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
- `nixosConfigurations.hedgehog`
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

`nixosModules.default` points at `modules/default.nix`, the same module imported
by this repo's host configurations. It exposes the `mine.*` option surface but
does not enable features by itself.

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

- `modules.homeManager.alacritty`
- `modules.homeManager.atuin`
- `modules.homeManager.fish`
- `modules.homeManager.git`
- `modules.homeManager.nixvim`
- `modules.homeManager.zellij`
- `modules.nixos.barrel`
- `modules.nixos.crown`
- `modules.nixos.default`
- `modules.nixos.goldenball`
- `modules.nixos.hedgehog`
- `modules.nixos.mountainball`
- `modules.nixos.r6t-base`
- `modules.nixos.r6t-home-shell`
- `modules.nixos.saguaro`

Compatibility exports should alias through this registry rather than importing
implementation files directly:

- `homeManagerModules.*` aliases `modules.homeManager.*`
- `nixosModules.default` aliases `modules.nixos.default`

`nixosConfigurations.*` also consumes the host-specific registry entries under
`modules.nixos.<host>`. Those host modules currently wrap the existing files in
`hosts/<host>/configuration.nix`; the host file contents have not been moved.

Host aspect registrations are colocated with their host directories. Each
`hosts/<host>/flake-module.nix` defines the matching `modules.nixos.<host>`
registry entry and imports `hosts/<host>/configuration.nix`.

The base NixOS module registry entry is colocated with the module tree:
`modules/flake-module.nix` defines `modules.nixos.default` as
`modules/default.nix`.

Portable Home Manager aspect registrations are colocated with their feature
directories. Each `modules/home/<name>/flake-module.nix` defines the matching
`modules.homeManager.<name>` registry entry, while the actual Home Manager
module remains `modules/home/<name>/default.nix`.

Profile aspects live under `modules/profiles/<name>/flake-module.nix`. These
are NixOS-class aspects that compose existing lower-level modules with
`lib.mkDefault` activation values. They provide host-file reduction without yet
rewriting every leaf module away from `mine.*.enable` gates.

Initial profile aspects:

- `modules.nixos.r6t-base` enables conservative fleet defaults: bootloader,
  fwupd, fzf, iperf, localization, nix, ssh, tailscale, user, common system
  packages, system fish shell support, and fail2ban SSH hardening.
- `modules.nixos.r6t-home-shell` enables the shell-oriented Home Manager stack:
  home-manager core, atuin, fish, git, nixvim, ssh, and zellij. This is the
  preferred name instead of `r6t-home-cli` because the profile describes an
  interactive shell environment rather than a generic CLI role.

`modules.nixos.r6t-base` owns behavior that used to live in the catch-all
`modules/nixos/nixos-r6t-baseline/default.nix` module. The split files are kept
inside the profile directory:

- `modules/profiles/r6t-base/ssh-hardening.nix`
- `modules/profiles/r6t-base/system-packages.nix`
- `modules/profiles/r6t-base/system-shell.nix`

`mine.nixos-r6t-baseline.enable` is legacy compatibility for hosts that have not
been migrated to profile imports yet. Do not add new behavior there.

Planned profile aspect names include `kde-workstation`, `server-base`,
`incus-host`, and `router`.

`flake/modules.nix` remains as the manual import list for these feature-owned
flake-parts modules. It should not own registry values directly unless there is
no better feature directory for the value yet.

This registry is intentionally small. Add new entries only when they are meant
to become reusable module API, not just because a file exists in `modules/`.

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

Humans can also check container discovery without building:

```fish
python3 containers/build.py --list
```

Agents must not run `containers/build.py` under this repository's instructions.
