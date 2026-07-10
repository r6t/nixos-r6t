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

- [ ] Incus pass.
- [ ] `incus`.
- [ ] `incus-log-collector`.
- [ ] `incus-nightly-rebuild`.
- [ ] `wg-metrics`.
- [ ] `exit-node-routing`.
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
- [ ] Server pass.
- [ ] `caddy`.
- [ ] `headscale`.
- [ ] `monitoring-services`.
- [ ] `immich`.
- [ ] `jellyfin`.
- [ ] `karakeep`.
- [ ] `n8n`.
- [ ] `uptime-kuma`.

## Phase 3: Slim Host Files

- Move reusable policy into profiles only when it has a real role.
- Shared firewall defaults.
- Sync-host ports.
- Incus-host ports/sysctls if truly common.
- `nix-daemon` memory limits into `nix-build-throttle`.
- Router LAN monitoring binds into `router` if safely derivable from router options.
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

- Do not move or rename direct `containers/*.nix`; those are public build attrs.
- Do not add helper `.nix` files directly under `containers/`.
- Keep runtime profiles under `hosts/<host>/incus-instances/`.
- Keep `instance_map.json` stable.
- Preserve Tailscale/DNS semantics; `mine.tailscale.enable` still has real meaning in containers because DNS override behavior depends on it.
- Split module internals first; avoid redesigning YAML/profile generation.

## Phase 5: LLM/GPU Cleanup

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

Phase 1 is complete. Phase 2 storage/network and GPU/LLM passes are complete. The next recommended step is the Phase 2 Incus pass.
