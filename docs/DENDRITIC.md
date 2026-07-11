# Dendritic Flake Structure

This flake uses small, colocated `flake-module.nix` entrypoints to register host,
profile, Home Manager, package, and container outputs. Regular implementation
files stay private until a directory explicitly opts in with `flake-module.nix`.

## Public Contract

Stable external outputs:

- `nixosConfigurations.{barrel,crown,goldenball,mountainball,saguaro}`
- `homeManagerModules.{default,alacritty,atuin,fish,git,nixvim,zellij}`
- `nixosModules.default`
- `packages.x86_64-linux.*`
- `checks.x86_64-linux.pre-commit-check`
- `lib.{mkNixosHost,mkRegisteredNixosHost}`

Repo-owned rebuilds use `nixosConfigurations.<host>`. Downstream Home Manager
users should import only the portable `homeManagerModules.*` they need, then
enable features through `mine.home.*` options.

`nixosModules.default` is compatibility-only. It imports `modules/default.nix`,
which exposes the legacy `mine.*` option surface for downstream NixOS users. It
does not enable repo features by itself, and repo-owned hosts do not import it.

## Registration

`flake/modules.nix` discovers immediate child directories with a
`flake-module.nix` under:

- `hosts/`
- `modules/home/`
- `modules/profiles/`

`flake/packages.nix` imports the container package module and discovers immediate
`pkgs/*/flake-module.nix` package modules.

This is intentional auto-discovery: adding a plain directory does nothing;
adding `flake-module.nix` opts that directory into flake outputs.

## Host Composition

Each `hosts/<host>/flake-module.nix` defines `modules.nixos.<host>` and imports:

- reusable profiles from `inputs.self.modules.nixos.*`
- `hosts/<host>/configuration.nix`

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
- `laptop-workstation`: laptop defaults shared by mountainball and goldenball.
- `office-desk`: Thunderbolt plus USB4 SFP+ dock support.
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

Profiles and repo hosts direct-import `options.nix` and `config.nix`. They should
not import a leaf `default.nix` just to turn on an enable option.

Once a feature is direct-imported, `mine.<leaf>.enable = false` no longer
disables it. Remove stale false-hook tombstones instead of keeping misleading
preferences.

`modules/default.nix` deliberately lists legacy flatpak, Home Manager, and NixOS
leaf wrappers. Keep entries there while they preserve downstream compatibility.

## Containers And Packages

Every `.nix` file directly under `containers/` is a public LXC image package:

- `packages.x86_64-linux.<container>`
- `packages.x86_64-linux.<container>-metadata`

`containers/lib/` is shared implementation, not image output surface.

Runtime Incus profiles, seeds, and instance maps stay under
`hosts/<host>/incus-instances/`. Do not move them into package generation. The
live profile sync intentionally applies checkout-path YAML while using a store
copy only as a restart trigger.

Custom packages use `pkgs/<name>/flake-module.nix`; currently this includes
`packages.x86_64-linux.rocmfp4-llama`.

## Compatibility Rules

- Preserve the public outputs listed above unless a migration is documented first.
- Keep `nixosConfigurations.<host>` as the operational rebuild entrypoint.
- Keep `homeManagerModules.*` stable for downstream flakes.
- Keep Incus image attr names and direct `containers/*.nix` build targets stable.
- Keep host-specific facts out of reusable profiles.
- Avoid new `mine.*.enable` activation hooks for repo-owned composition.
- Delete empty/no-op modules instead of preserving inert option surface.
- Do not genericize measured GPU/LLM tuning; keep crown TensorRT-LLM and
  goldenball ROCmFP4 llama.cpp values host/container-local.

## Validation

Use no-build checks for flake structure changes:

```fish
./format.fish
git diff --check
nix eval --json .#nixosConfigurations --apply builtins.attrNames
nix eval --json .#modules.nixos --apply builtins.attrNames
nix eval --json .#homeManagerModules --apply builtins.attrNames
nix eval --json .#packages.x86_64-linux --apply builtins.attrNames
for host in barrel crown goldenball mountainball saguaro
    nix eval --raw ".#nixosConfigurations.$host.config.system.build.toplevel.drvPath"
end
```

Agents must not build or activate systems, run `containers/build.py`, or run
`containers/relaunch.py`.
