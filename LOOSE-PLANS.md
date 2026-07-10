# Loose Plans

## Recommended Target

- Repo-owned hosts import only `modules.nixos.<host>` entries.
- Host modules compose reusable profiles plus host-local facts.
- Profiles are self-contained and direct-import needed `options.nix` and `config.nix`.
- `modules/default.nix` remains only as external compatibility for `nixosModules.default`, not used by repo hosts.
- Root `containers/*.nix` names stay stable as build attrs.
- `homeManagerModules.*`, `nixosModules.default`, packages, checks, and `nixosConfigurations.*` stay stable.

## Phase 0: Stabilize Current Work

- [x] Finish the already-done router/SOPS split as the baseline.
- [x] Remember current new files are untracked; normal non-`path:` evals/rebuilds will fail until the user tracks them.
- [x] Continue validation with `path:/home/r6t/git/nixos-r6t#...` until then.

## Phase 1: Remove Host Dependency On `modules/default.nix`

- [x] Make profiles self-contained first.
- [x] `r6t-home-core`: import upstream `home-manager.nixosModules.home-manager` and local `home/nixvim/default.nix`.
- [x] `kde-workstation`: import upstream `nix-flatpak.nixosModules.nix-flatpak`.
- [x] `incus-host`: import `modules/nixos/incus/default.nix` initially.
- [x] `nfs-photos-client` and `nfs-pictures-export`: import `modules/nixos/nfs/default.nix`.
- [x] `nvidia-container-host`: import `modules/nixos/nvidia-cuda/default.nix`.
- [x] `zfs-host`: import `modules/nixos/zfs-pool/default.nix`.
- [x] Add host-local direct imports where only one host needs the module.
- [x] `crown`: `caddy`, `mountLuksStore`, `incus-nightly-rebuild`, `wg-metrics`.
- [x] `goldenball`: `asusctl`, `llama-cpp`.
- [x] `saguaro`: `mountLuksStore`.
- [x] Remove `../../modules/default.nix` from all hosts.
- [x] Remove direct upstream `home-manager` imports where covered by `r6t-home-core`.
- [x] Remove direct upstream `nix-flatpak` imports where covered by `kde-workstation`.
- [x] Validation passed: `./format.fish`, `git diff --check`, output-name evals, all host toplevel evals, targeted Phase 1 evals, downstream override evals.

## Phase 2: Convert Remaining Profile-Owned Legacy Enables

- [x] Incus pass.
- [x] `incus`.
- [x] `incus-log-collector`.
- [x] `incus-nightly-rebuild`.
- [x] `wg-metrics`.
- [x] `exit-node-routing`.
- [x] Storage/network pass.
- [x] `nfs`.
- [x] `zfs-pool`.
- [x] `mountLuksStore`.
- [x] Storage/network validation passed.
- [x] GPU/LLM pass.
- [x] `nvidia-cuda`.
- [x] `llama-cpp`.
- [x] `open-webui`.
- [x] `ollama` retired as unused.
- [x] `stable-diffusion-cpp`.
- [x] GPU/LLM validation passed.
- [x] Server pass.
- [x] `caddy`.
- [x] `headscale` retired as unused.
- [x] `monitoring-services`.
- [x] `immich`.
- [x] `jellyfin`.
- [x] `karakeep` retired as unused.
- [x] `n8n` retired as unused.
- [x] `uptime-kuma` retired as unused.
- [x] Server validation passed.
- [x] Incus validation passed.

## Warning Cleanup Before Incus Pass

- [x] Grafana Loki datasource header value moved out of `secureJsonData`.
- [x] Container packages use native `system.build.images.lxc` and `lxc-metadata`.
- [x] nixvim treesitter grammars follow the configured treesitter package.
- [x] Local host and representative container evals are warning-free.
- [ ] Downstream override eval still emits Nix's expected lock-file override warning.
- [ ] Downstream `nvim-treesitter-legacy` warning remains in the downstream nixpkgs pin's plugin conflict check, not in this repo's runtime plugin closure.

## Phase 3: Targeted Host File Cleanup

- Audit host files for repeated active behavior before moving anything.
- Move reusable policy into profiles only when it has a real role or a replacement-host story.
- Keep firewall ports, Incus sysctls, NIC pins, storage ordering, and router monitoring binds host-local unless at least two hosts share the exact policy.
- Move `nix-daemon` memory limits into `nix-build-throttle` only if another host needs the same policy.
- Remove stale commented-out blocks and obsolete tombstones when encountered.
- Keep host-local facts.
- Hardware imports.
- `system.stateVersion`.
- Hostnames and host IDs.
- PCI path interface pins.
- Static IPs/gateways/bridges.
- UUIDs, key files, mount points.
- SOPS paths.
- DHCP reservations.
- `goldenball` kernel/GPU stability tuning.
- `crown` concrete Caddy route selection.

## Phase 4: Incus/Container Cleanup

- Native LXC package generation via `system.build.images.lxc` / `lxc-metadata` is complete; do not reintroduce `nixos-generators`.
- Do not move or rename direct `containers/*.nix`; those are public build attrs.
- Do not add helper `.nix` files directly under `containers/`.
- Keep runtime profiles under `hosts/<host>/incus-instances/`.
- Keep `instance_map.json` stable.
- Preserve Tailscale/DNS semantics; `mine.tailscale.enable` still has real meaning in containers because DNS override behavior depends on it.
- Avoid redesigning YAML/profile generation unless there is a focused operational reason.

## Phase 5: LLM/GPU Cleanup

- Mostly satisfied by the Phase 2 GPU/LLM pass; revisit only for a concrete hardware or serving change.
- Preserve measured tuning exactly.
- Keep `crown` TensorRT-LLM separate from `goldenball` llama.cpp/ROCmFP4.
- Do not genericize GPU passthrough.
- Avoid new profiles unless a second host actually shares behavior.
- Keep model IDs and flags stable, especially `goldenball`'s ROCmFP4 config and `crown`'s TensorRT service.

## Phase 6: Compatibility Finalization

- Keep `nixosModules.default` and `homeManagerModules.*` as stable external APIs.
- Keep legacy wrappers in `modules/default.nix` while they preserve downstream compatibility.
- Remove only dead/no-op modules.
- Internal rule: no repo host should require `modules/default.nix`.

## Validation After Each Phase

- `./format.fish`.
- `git diff --check`.
- Output-name evals.
- All host toplevel drvPath evals.
- Targeted evals for touched domains.
- Downstream `~/git/nix-work-r6t` override evals.
- Use `path:/home/r6t/git/nixos-r6t#...` while new imported files are untracked.

## Decision

Phase 1 and Phase 2 are complete. Warning cleanup is complete locally; downstream warning cleanup needs a downstream nixpkgs refresh or local downstream policy decision. The next useful repo work is targeted host-file cleanup only where repeated behavior is proven, not broad abstraction.
