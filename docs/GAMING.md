# Gaming on mountainball

mountainball is a Framework 13 AMD (Ryzen 7040 series) laptop. When docked at a desk via
a Thunderbolt eGPU it is the primary gaming system and local LLM host. It also operates
regularly as an undocked laptop.

## Hardware

- **Host:** Framework Laptop 13 (AMD Ryzen 7040, Radeon 780M iGPU)
- **eGPU:** Radeon AI Pro R9700 32 GB in a TH3P4G3 V3 enclosure (85W PD, single TB3/4 port)
- **Connection:** Thunderbolt 4 (USB4), ~32 Gbps, PCIe 3.0 x4 effective bandwidth
- **Desk display:** connected to eGPU outputs (R9700 drives it)
- **Laptop display:** driven by AMD iGPU — used simultaneously when docked (music,
  chat, browser, terminal alongside gaming on desk monitor)

## Operating modes

mountainball has two distinct configurations handled via NixOS specialisations:

### Undocked (default boot)

AMD iGPU only (Radeon 780M). Normal laptop usage. Default NixOS boot entry — boots
automatically without user input after the systemd-boot timeout.

### Docked at desk (`egpu` specialisation)

R9700 eGPU active. Both iGPU and eGPU use `amdgpu` — no driver complexity.
Select the `egpu` entry in the boot menu.

**Workflow:**

1. Plug TH3P4G3 into the laptop before or at power-on
2. At the systemd-boot menu, select the `egpu` specialisation entry
3. Boot proceeds with KWin directed to use the R9700 as primary compositor

**Verify after login:**

```fish
qdbus org.kde.KWin /KWin supportInformation | grep "OpenGL renderer"
# expected: AMD Radeon RX ... (R9700)
# NOT: AMD Radeon 780M (that's the iGPU — wrong primary)
```

## NixOS specialisation

The `egpu` specialisation in `hosts/mountainball/configuration.nix`:

```nix
specialisation.egpu.configuration = {
  system.nixos.tags = [ "egpu" ];

  # Thunderbolt PCIe hotplug
  boot.kernelParams = [
    "pcie_ports=native"
    "pci=hpmmiosize=128M,hpmmioprefsize=16G"
  ];

  # Force PCIe Gen 3 on amdgpu eGPU — AMD USB4 may fall back to Gen 1 without this
  boot.extraModprobeConfig = ''
    options amdgpu pcie_gen_cap=0x40000
  '';

  # R9700 (card0) as primary compositor, 780M iGPU (card1) as secondary (laptop display)
  environment.sessionVariables = {
    KWIN_DRM_DEVICES = "/dev/dri/card0:/dev/dri/card1";
  };

  # ROCm ollama for local LLM inference on the 32 GB R9700
  mine.ollama = {
    enable = true;
    acceleration = "rocm"; # fallback: "vulkan" if ROCm segfaults on RDNA 4
  };
};
```

### Why specialisations

The two modes have different correct GPU states:

- Undocked: 780M iGPU only, auto-selected by KWin
- Docked: R9700 must be compositor primary (desk monitor on R9700 outputs), 780M secondary

`KWIN_DRM_DEVICES` cannot be correct for both modes simultaneously in a flat config.
The specialisation makes the decision at boot time when the hardware state is known.

### Why AMD+AMD is simpler than the previous NVIDIA setup

The previous eGPU was an RTX 4070 Ti (NVIDIA). It was replaced with the R9700 partly
due to the complexity it added. For reference:

- NVIDIA required `mine.nvidia-cuda`, `allowExternalGpu`, GSP firmware management,
  `allowUnfree`, and a custom `nvidia-load` systemd service to work around a race
  between `boltd` authorization and `systemd-modules-load` loading NVIDIA modules
  ~1 second before the TB PCIe tunnel was established
- AMD: `amdgpu` loads via udev modalias when the device appears — no timing race,
  no proprietary driver stack, no authorization dependency

### Card number stability

With R9700 connected at boot, it enumerates as `card0` and the 780M as `card1`.
Both use `amdgpu` — ordering is by PCIe root port, stable across reboots.

If the numbers ever swap (check `ls -la /dev/dri/by-path/`), update
`KWIN_DRM_DEVICES` in the specialisation.

**Note on `KWIN_DRM_DEVICES` colon crash:** this variable uses `:` as a list separator.
Do NOT use `/dev/dri/by-path/pci-*` paths here — PCI addresses contain `:` which KWin
splits on, causing it to find zero devices and crash SDDM. Use only `/dev/dri/cardN`
paths. This was a confirmed crash with the previous NVIDIA setup.

## Steam and gaming stack

`mine.steam.enable = true` is in the base config (present in both modes):

- `programs.steam` — sandboxed via bubblewrap, home bound to `~/steam-sandbox`
- `mangohud` — GPU/CPU/frame overlay (injected into Steam FHS)
- `gamescope` — Wayland-native game session compositor
- `gamemode` — system-level CPU/scheduler optimizations
- `proton-ge-bin` — Proton-GE via `extraCompatPackages`
- `moonlight-qt` — Moonlight streaming client (for receiving streams)
- Real-time scheduling limits for the user

Sandbox: game saves and libraries live in `~/steam-sandbox`. `/mnt` is hidden.

## Game performance tuning (eGPU-specific)

### Fullscreen mode

Always run games in fullscreen. KWin bypasses the compositor (unredirect) in
fullscreen, eliminating one copy step.

### Proton version

Use Proton-GE (`GE-ProtonX-XX`) for most games.

### DX11 games (DXVK) — Rocket League and similar

Rocket League runs DX11 via DXVK under Proton. Over Thunderbolt, dynamic buffer
uploads can cause extra TB round-trips. If frame times are spikey, try:

```
DXVK_CONFIG="d3d11.cachedDynamicResources = a" %command%
```

Test without it first — it may not be needed.

### DX12 games (VKD3D)

For lower-than-expected DX12 performance over eGPU:

```
VKD3D_CONFIG=force_host_cached %command%
```

### MangoHud overlay

```
MANGOHUD=1 %command%
```

Monitors GPU utilization, VRAM usage, frame times. The R9700 has 32 GB — VRAM
pressure is unlikely for games, but useful for confirming the right GPU is active.

### AMD-specific: ReBAR / SAM

The R9700 supports Resizable BAR (Smart Access Memory). Over Thunderbolt this may
be limited by the enclosure bridge topology. `pcie_gen_cap=0x40000` ensures Gen 3
speeds. If bandwidth tests show unexpectedly low throughput, also check:

```fish
# Confirm PCIe Gen 3 x4 is negotiated (ignore dmesg "2.5 GT/s" cosmetic bug)
lspci -vv -s $(lspci | grep "Radeon RX" | grep -v "780M" | cut -d' ' -f1) | grep LnkSta
```

`RADV_PERFTEST=nosam` can be set as a Steam launch option to disable SAM if it causes
instability on the TB link (should not be needed with Mesa 23.1+ at PCIe 3.0x4).

## Local LLM inference on mountainball (docked)

The R9700's 32 GB VRAM fits large models fully on-GPU, making mountainball a capable
local LLM host when docked with the eGPU.

### VRAM capacity

- 70B models at Q4 (~35 GB): fits with ~1 GB headroom — tight, test in practice
- 34B models at Q8 (~34 GB): fits
- 32B models (Qwen2.5-Coder-32B, DeepSeek-Coder-V2-Lite) at Q8: comfortable fit
- 14B models at Q8 (~14 GB): plenty of headroom

### Ollama with ROCm

Enabled in the `egpu` specialisation via `mine.ollama`:

```nix
mine.ollama = {
  enable = true;
  acceleration = "rocm";
};
```

The ollama module handles `MemoryDenyWriteExecute = false` automatically for ROCm
(required for JIT kernel compilation). If ROCm segfaults on RDNA 4 (check nixpkgs
ROCm support status for the R9700 architecture at install time), switch to `"vulkan"`.

Ollama listens on `127.0.0.1:11434` by default. To expose on LAN (e.g. for OpenCode
on other machines), set `mine.ollama.host = "0.0.0.0"`.

### llamacpp directly

The `mine.llama-cpp` module offers more control over offload layers, context size,
and batching. Useful for benchmarking and tuning. Enable alongside or instead of
ollama in the specialisation as needed.

### OpenCode integration

The nixvim module (`mine.home.nixvim`) manages OpenCode. Once a local model is
running via ollama, OpenCode can be pointed at `http://localhost:11434` for local
inference when docked. Future work — document in nixvim module when implemented.

## Troubleshooting

### KWin compositing on 780M instead of R9700 (egpu specialisation)

Symptom: desktop feels sluggish, games show low GPU utilization on R9700.

Diagnosis:

```fish
qdbus org.kde.KWin /KWin supportInformation | grep "OpenGL renderer"
# if this shows "AMD Radeon 780M" kwin is on the iGPU, not the eGPU
```

Cause 1: Wrong boot entry — booted the default undocked entry instead of `egpu`.
Fix: reboot and select `egpu` from boot menu.

Cause 2: Card enumeration order changed — 780M became `card0`, R9700 became `card1`.
Fix: check `ls -la /dev/dri/by-path/` and update `KWIN_DRM_DEVICES` in the
specialisation accordingly, then rebuild.

### SDDM shows no login screen (kwin exits immediately)

Symptom: black screen after selecting `egpu` boot entry.

Cause: `KWIN_DRM_DEVICES` path is invalid. Check for by-path symlinks with colons.

Diagnosis:

```fish
journalctl -b -1 -u sddm --grep "kwin_wayland_drm"
# look for "Failed to open drm device" and "No suitable DRM devices have been found"
```

Recovery: reboot into the default (undocked) entry, fix `KWIN_DRM_DEVICES`, rebuild.

### amdgpu eGPU not detected at all

Symptom: `lspci -d ::03xx` shows only the 780M, no R9700.

Cause 1: Thunderbolt device not authorized by boltd.
Fix: `boltctl list` — if TH3P4G3 shows `status: unauthorized`, run
`boltctl enroll <uuid>` to store it. Should auto-enroll after first use.

Cause 2: PCIe tunnel not established before boot completed.
Fix: ensure TH3P4G3 is connected before power-on, not hot-plugged during POST.
amdgpu handles hotplug via udev but the `egpu` specialisation's `KWIN_DRM_DEVICES`
is set at session start — a mid-session hot-plug will show the display but not as
the compositor primary until next login.

### PCIe link speed shown as 2.5 GT/s in lspci

Known cosmetic issue on AMD USB4 controllers. `pcie_gen_cap=0x40000` ensures the
driver negotiates Gen 3 — confirm with actual bandwidth tests rather than dmesg.
