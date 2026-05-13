# Gaming on mountainball

mountainball is a Framework Laptop 13 (AMD Ryzen 7040 series) with the integrated
Radeon 780M GPU. Gaming here is light/casual — older titles, indies, and streamed
games via Moonlight. Heavier workloads run on remote machines.

## Hardware

- **Host:** Framework Laptop 13 (AMD Ryzen 7 7840U, Radeon 780M iGPU / gfx1103, RDNA 3)
- **Display:** internal 13" panel, plus external monitor when at desk (via USB-C DP-alt)
- **Driver:** in-kernel `amdgpu`. No proprietary stack, no driver complexity.

There is no dedicated GPU — RAM is shared between CPU and iGPU. The 780M is
solid for older or less demanding titles but is not a discrete-GPU replacement.

> **History:** mountainball previously hosted a Radeon AI Pro R9700 32 GB eGPU
> over Thunderbolt for serious gaming + local LLM inference, with a NixOS
> specialisation toggling the docked configuration. The R9700 has since moved
> to crown for headless inference, and the eGPU specialisation was removed.
> See `git log -- hosts/mountainball/configuration.nix` if reviving an eGPU
> setup is ever on the table.

## Steam and gaming stack

Enabled in the base config via `mine.steam.enable = true`:

- `programs.steam` — sandboxed via bubblewrap, home bound to `~/steam-sandbox`
- `mangohud` — GPU/CPU/frame overlay (injected into the Steam FHS)
- `gamescope` — Wayland-native game session compositor
- `gamemode` — system-level CPU/scheduler optimizations
- `proton-ge-bin` — Proton-GE via `extraCompatPackages`
- `moonlight-qt` — Moonlight client for streaming from a remote host
- Real-time scheduling limits granted to the user

Sandbox: game saves and libraries live in `~/steam-sandbox`. `/mnt` is hidden
from the sandbox.

## Tips for the 780M iGPU

### Reasonable expectations

The 780M handles:

- Most 2D / pixel-art / indie titles
- Older 3D titles (pre-2018) at 1080p
- Modern lightweight titles (Stardew Valley, Hades, Vampire Survivors, etc.)
- Streamed games via Moonlight (the iGPU is just a video decoder in this case)

It struggles with modern AAA. Cap framerates to reduce thermal throttling on
the laptop chassis — the 780M can sustain 30–60 fps on appropriate titles but
will downclock under prolonged thermal load.

### MangoHud overlay

```
MANGOHUD=1 %command%
```

Useful for monitoring CPU/GPU package temps and APU power draw. Both share
the same TDP budget on the Ryzen 7040.

### Fullscreen mode

Run games in fullscreen — KWin bypasses the compositor (unredirect) in
fullscreen, which matters more on an iGPU than on a discrete card.

### Proton version

Use Proton-GE (`GE-ProtonX-XX`) for most games, especially older or DRM-heavy ones.

### Streaming with Moonlight

`moonlight-qt` is included in the gaming stack. For demanding titles, stream
from a more capable host on the LAN rather than running locally on the iGPU.

## Troubleshooting

### Thermal throttling under load

Symptom: framerate drops after a few minutes of play. mangohud shows GPU
clocks dropping below base.

Cause: APU TDP / chassis cooling limit on a 13" laptop.

Mitigations:

- Cap framerate (in-game, or via `mangohud --fps-limit=60`)
- Lower internal render resolution
- Plug in AC power (some titles default to power-saving on battery)
- Use `gamemode` (already enabled) — boosts CPU governor while a game runs

### Game wants Vulkan but iGPU not detected

The 780M supports Vulkan via RADV (Mesa). Confirm with:

```fish
vulkaninfo --summary | head -20
# expected: AMD Radeon 780M Graphics (RADV PHOENIX)
```

If missing, check that `mesa` is in the system closure (it is, via `mine.kde`)
and that the `amdgpu` kernel module is loaded (`lsmod | grep amdgpu`).
