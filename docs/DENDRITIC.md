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

There is intentionally no bundled `homeManagerModules.default` export yet. The
current downstream contract is explicit per-module imports; broader aggregate
exports can be added later as an additive compatibility layer.

### Linux Packages

The package contract is currently Linux-only under `packages.x86_64-linux`.

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
- Treat `containers/` and `pkgs/` as lower-level implementation directories unless explicitly migrated later.

## No-Build Validation Commands

These commands evaluate output names without building or activating anything:

```fish
nix eval --json .#nixosConfigurations --apply builtins.attrNames
nix eval --json .#homeManagerModules --apply builtins.attrNames
nix eval --json .#packages.x86_64-linux --apply builtins.attrNames
nix eval --json .#checks.x86_64-linux --apply builtins.attrNames
```

Humans can also check container discovery without building:

```fish
python3 containers/build.py --list
```

Agents must not run `containers/build.py` under this repository's instructions.
