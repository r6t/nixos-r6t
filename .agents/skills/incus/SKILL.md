---
name: incus
description: Use for creating, modifying, reviewing, or debugging Incus/LXC container images, profiles, cloud-init, networking, GPU passthrough, deployment, or runtime behavior in this repository.
---

# Incus

Read `docs/INCUS.md` before making changes.

Follow the container pipeline and ownership boundaries documented there. Container definitions live in `containers/`; host-specific profiles and seed files live under `hosts/<host>/incus-instances/`.

Never run `containers/build.py`, `containers/relaunch.py`, or any Nix build or activation command. Use static checks and `./format.fish` only.
