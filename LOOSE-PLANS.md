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

- [x] Audit host files for repeated active behavior before moving anything.
- [x] Move reusable policy into profiles only when it has a real role or a replacement-host story.
- [x] Keep firewall ports, Incus sysctls, NIC pins, storage ordering, and router monitoring binds host-local unless at least two hosts share the exact policy.
- [x] Keep `nix-daemon` memory limits host-local; only `mountainball` has the memory cap, while `nix-build-throttle` owns shared CPU quota.
- [x] Remove stale commented-out blocks and obsolete tombstones when encountered.
- [x] Split host-owned `asusctl` so `goldenball` direct-imports its config and no host imports leaf `default.nix` wrappers.
- [x] Keep host-local facts.
- [x] Hardware imports.
- [x] `system.stateVersion`.
- [x] Hostnames and host IDs.
- [x] PCI path interface pins.
- [x] Static IPs/gateways/bridges.
- [x] UUIDs, key files, mount points.
- [x] SOPS paths.
- [x] DHCP reservations.
- [x] `goldenball` kernel/GPU stability tuning.
- [x] `crown` concrete Caddy route selection.

## Phase 4: Incus/Container Cleanup

- Native LXC package generation via `system.build.images.lxc` / `lxc-metadata` is complete; do not reintroduce `nixos-generators`.
- Do not move or rename direct `containers/*.nix`; those are public build attrs.
- Do not add helper `.nix` files directly under `containers/`.
- Keep runtime profiles under `hosts/<host>/incus-instances/`.
- Keep `instance_map.json` stable.
- Preserve Tailscale/DNS semantics; `mine.tailscale.enable` still has real meaning in containers because DNS override behavior depends on it.
- Avoid redesigning YAML/profile generation unless there is a focused operational reason.
- [x] Audit profiles, seed files, and script workflow for focused operational risks.
- [x] Make `containers/build.py` avoid the shared `result` symlink and fail on real image import errors.
- [x] Make `containers/relaunch.py` surface failed incus stop/delete/launch commands instead of treating stderr as the only failure signal.
- [x] Make `incus-log-collector` avoid replaying historical journal entries when forwarders restart.
- [x] Update `docs/INCUS.md` for native LXC package generation.
- [x] Delete stale/conflicting standalone `pocket-id` profile and seed files now that PocketID runs in `spire`.
- [x] Make `incus-profile-sync` prune retired non-default profiles when YAML files are removed.
- [x] Give `spire` a default LAN DNS upstream while keeping Tailscale split-DNS.
- [x] Leave `sts` host port `47813` private and out of caddy routes.
- [x] Remove the concrete Tailscale tailnet domain from container DNS config and docs.
- [x] Keep `containers/relaunch.py` on the stop/delete/launch cattle model; persistent state belongs on host bind mounts.
- [x] Keep `incus-profile-sync` applying checkout-path YAML while documenting the store copy as a restart trigger only.

## Phase 5: LLM/GPU Cleanup

- Mostly satisfied by the Phase 2 GPU/LLM pass; revisit only for a concrete hardware or serving change.
- Preserve measured tuning exactly.
- Keep `crown` TensorRT-LLM separate from `goldenball` llama.cpp/ROCmFP4.
- Do not genericize GPU passthrough.
- Avoid new profiles unless a second host actually shares behavior.
- Keep model IDs and flags stable, especially `goldenball`'s ROCmFP4 config and `crown`'s TensorRT service.
- [x] Audit active LLM/GPU configs without changing measured model IDs, flags, context, cache, or backend settings.
- [x] Refresh docs/comments for current crown NVIDIA/TensorRT and goldenball ROCmFP4 roles.
- [x] Remove stale/duplicated LLM tuning docs, including obsolete `--cache-reuse` baseline wording.

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

Phase 1, Phase 2, targeted Phase 3 host cleanup, focused Phase 4 Incus/container cleanup, and Phase 5 LLM/GPU cleanup are complete. Warning cleanup is complete locally; downstream warning cleanup needs a downstream nixpkgs refresh or local downstream policy decision. The next useful repo work is Phase 6 compatibility finalization.
