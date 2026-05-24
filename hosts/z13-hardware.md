# ASUS ROG Flow Z13 (GZ302EA) — nixos-hardware upstream plan

This file documents the plan to contribute the ASUS ROG Flow Z13 (2025, GZ302EA, AMD
Ryzen AI MAX+ 395 / Strix Halo) to the [nixos-hardware](https://github.com/NixOS/nixos-hardware)
repository so other NixOS users on this device get the device-specific stability fixes
and palm-rejection workarounds without having to discover them all over again.

This is a planning + handoff document. The implementation prompt at the bottom is
meant to be fed to a local Qwen3.6-27B (or any capable coding model) running on the
goldenball llama-server, with read access to this flake and the nixos-hardware
reference repo.

## Status of the source workarounds

The Z13-specific fixes currently live in `hosts/goldenball/configuration.nix` and a
few cross-cutting modules (`modules/nixos/bluetooth/default.nix`). All of them have
been validated on actual hardware (BIOS GZ302EA.311, kernel 7.0.8, Mesa 26.1.0).
This document captures everything so an LLM agent can lift it cleanly into a
nixos-hardware module without reading the whole flake.

## Hardware summary

| Component                | Detail                                                                          |
| ------------------------ | ------------------------------------------------------------------------------- |
| Model                    | ASUS ROG Flow Z13 (2025), GZ302EA                                               |
| CPU                      | AMD Ryzen AI MAX+ 395 (Strix Halo, Zen 5 + RDNA 3.5 + Phoenix iGPU)             |
| GPU                      | Radeon 8060S (RDNA 3.5 / gfx1151 / DCN 3.5.1), 4 GB dedicated VRAM + ~96 GB GTT |
| RAM                      | LPDDR5X soldered, up to 128 GB unified                                          |
| Display                  | 13.4" Tianma TL134ADXP03, 2560×1600, 180 Hz, FreeSync 48–180 Hz, eDP            |
| Wi-Fi/BT                 | MediaTek MT7925 (PCIe `mt7925e` for Wi-Fi, USB IMC Networks 13d3:3608 for BT)   |
| Touchscreen + pen        | ELAN9008 04F3:43C7 (i2c-hid, multitouch + stylus)                               |
| Detachable keyboard dock | USB 0B05:1A30 (touchpad + Mouse + keyboard interfaces)                          |
| Audio                    | Cirrus CS35L41 speaker amp                                                      |
| Storage                  | NVMe Gen4, M.2 2230                                                             |

## Categorized fixes

### A. Core platform (always-on)

| Fix                                             | Source location        | Why                                                                                                  |
| ----------------------------------------------- | ---------------------- | ---------------------------------------------------------------------------------------------------- |
| `kvm-amd` kernel module                         | `boot.kernelModules`   | Standard for AMD CPUs                                                                                |
| `amd_pstate=guided`                             | `kernelParams`         | Better power scaling on Zen 5 / Phoenix                                                              |
| `iommu=pt`                                      | `kernelParams`         | Zero-cost translation for IOMMU on USB4 / GPU                                                        |
| `mem_sleep_default=deep` is **NOT** appropriate | (intentionally absent) | Strix Halo only supports S0 (s2idle) and S4 (hibernate). No S3 deep sleep.                           |
| AMD common imports                              | `imports`              | `common/cpu/amd`, `common/cpu/amd/pstate.nix`, `common/gpu/amd`, `common/pc/laptop`, `common/pc/ssd` |
| `hardware.sensor.iio.enable = mkDefault true`   | `hardware.sensor.iio`  | 2-in-1 detachable, needs accelerometer for auto-rotation                                             |

### B. Display engine stability (DCN 3.5.1)

These prevent the page-flip timeout / system freeze that hits during fullscreen
VRR gameplay and other display-engine stress.

| Param                   | Value        | Effect                                                                                               | Source / cite                                                  |
| ----------------------- | ------------ | ---------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| `amdgpu.dcdebugmask`    | `0x412`      | Disable PSR + PSR-SU + Panel Replay + Stutter                                                        | Arch wiki §6.11; r/FlowZ13 "pageflip timed out"; drm/amd #4141 |
| `amdgpu.sg_display`     | `0`          | Disable scatter-gather display on iGPU                                                               | th3cavalry/strix-halo-linux-setup                              |
| `amdgpu.gpu_recovery`   | `1`          | Soft-reset display engine on timeout instead of hard freeze                                          | r/FlowZ13 octeeeeee comment                                    |
| `amdgpu.ppfeaturemask`  | `0xfff73fff` | Default minus `PP_GFXOFF_MASK` (0x8000) + `PP_STUTTER_MODE` (0x20000) + `PP_OVERDRIVE_MASK` (0x4000) | Arch wiki §5.3.1; OD warning in dmesg                          |
| `amdgpu.abmlevel`       | `0`          | Disable adaptive brightness (causes timing issues on external displays)                              | nixos-hardware/asus/flow/gv302x precedent                      |
| `amdgpu.freesync_video` | `1`          | Enable FreeSync VRR support in DRM driver for the eDP panel                                          | Required for KWin/Hyprland VRR policies to take effect         |

The upstream nixos-hardware module should expose these as **opt-in or opt-out
options** following the gv302x/amdgpu/default.nix pattern, not unconditionally
applied. Suggested option layout:

```nix
options.hardware.asus.flow.gz302ea.amdgpu = {
  recovery.enable = mkOption { default = true; ... };           # gpu_recovery=1
  sg_display.enable = mkOption { default = false; ... };        # sg_display=0 when disabled
  pageflipFix.enable = mkOption { default = true; ... };        # dcdebugmask=0x412
  freesyncVideo.enable = mkOption { default = true; ... };
  abm.enable = mkOption { default = false; ... };                # abmlevel=0 when disabled
  overdrive.enable = mkOption { default = false; ... };          # excludes PP_OVERDRIVE
};
```

### C. Detachable keyboard dock (USB 0B05:1A30)

Three problems, three fixes, all required for usable typing.

#### 1. Blacklist `hid_asus`

The dock's HID interfaces get claimed by `hid-asus`, which exposes the touchpad
without proper multi-touch contact axes (no pressure, no contact size, no width).
Without those, libinput cannot do palm rejection — palm contacts look like
fingers and move the cursor freely. `hid-asus` also exposes a parallel REL_X/Y
"Mouse" subdevice that bypasses DWT.

Falling back to `hid-multitouch` exposes the device with proper internal-touchpad
characteristics (full ABS_MT axes, INPUT_PROP_BUTTONPAD), restoring palm
detection and DWT pairing with the keyboard.

**Tradeoff**: lose ASUS-specific HID functionality (RGB control via hid-asus,
some hotkeys). RGB is recoverable via asusctl over the platform driver path.

```nix
boot.blacklistedKernelModules = [ "hid_asus" ];
```

Source: r/FlowZ13 NixOS user k7_u (2025-05); Linux Mint forum thread.

#### 2. Force touchpad integration to `internal` via udev hwdb

systemd's `65-integration.rules` tags the dock touchpad as `external` because the
USB port is `removable` (the keyboard physically detaches). libinput then
refuses to pair it with the laptop keyboard for DWT. The hwdb lookup runs in
`70-touchpad.rules` after the integration rules, and overrides the property.

```
# /etc/udev/hwdb.d/61-gz302ea-touchpad-internal.hwdb
touchpad:usb:v0b05p1a30:*
 ID_INPUT_TOUCHPAD_INTEGRATION=internal
```

Format reference: `/lib/udev/hwdb.d/70-touchpad.hwdb` in the systemd source tree.

#### 3. Ignore the spurious Mouse REL subdevice

The dock exposes both a Mouse (REL_X/Y) and a Touchpad (ABS_MT) from the same
HID interface. DWT does not apply to pointer/mouse devices, so palm contact
during typing generates REL cursor movement that bypasses all libinput
suppression. Ignoring the Mouse node is safe because the Touchpad handles all
cursor movement correctly.

```
SUBSYSTEM=="input", ATTRS{id/vendor}=="0b05", ATTRS{id/product}=="1a30", ENV{ID_INPUT_MOUSE}=="1", ENV{ID_INPUT_TOUCHPAD}!="1", ENV{LIBINPUT_IGNORE_DEVICE}="1"
```

Upstream tracking: libinput issues #1103, #1283.

### D. Wi-Fi / Bluetooth (MediaTek MT7925)

```nix
boot.kernelModules = [ "mt7925e" ];
boot.extraModprobeConfig = "options mt7925e disable_aspm=1";
```

`disable_aspm=1` improves stability — survives cold boots after failed s2idle
resume. Loading the module at boot (rather than via udev) further hardens
against resume races.

#### Bluetooth — temporary kernel patch (only while applicable)

A kernel regression in 7.0.7 / 6.19.12 (bad commit `634a4408c061`) breaks MT7925
BT init with `Failed to send wmt func ctrl (-22)`. Upstream fix is
`e3ac0d9f1a205f33a43fba3b79ef74d2f604c78b` (May 14 2026). nixpkgs's 7.0.8
(May 15 build) does NOT yet include the backport.

The flake currently carries this as a `boot.kernelPatches` entry in
`modules/nixos/bluetooth/default.nix`. **This patch should NOT go upstream to
nixos-hardware** — it's a transient kernel regression that will be obsolete
within weeks. Document it in the upstream module's README or a comment, but
don't bake it into the module body. Leave in your private flake only.

### E. USB4 / Thunderbolt (Strix Halo host routers)

Strix Halo USB4 host routers (1022:158d, 1022:158e) use DPIA adapters that
crash ~10 minutes after boot if the router enters runtime suspend. Intel PCIe
switches inside attached USB4 hubs (8086:0b26, 8086:15ef) must not enter D3cold
because they are hotplugged and fail to wake.

```
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158d", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158e", ATTR{power/control}="on"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x0b26", ATTR{d3cold_allowed}="0"
ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15ef", ATTR{d3cold_allowed}="0"
```

The Intel hub rules are inert when no hub is connected, so they're safe to
include unconditionally.

### F. Sleep / lid policy

```nix
# Strix Halo only supports S0 (s2idle) and S4 (hibernate) — no S3 deep sleep.
systemd.sleep.settings.Sleep = {
  HibernateDelaySec = "30m";
  SuspendState = "freeze";
};
```

The upstream module shouldn't enforce a lid-switch policy (that's user
preference / desktop-environment territory), but it should set
`SuspendState = "freeze"` because Strix Halo cannot do `mem` (S3) at all —
trying causes a hard hang on suspend.

## What does NOT belong in nixos-hardware

These items in the current flake are user-specific or workflow-specific and
should stay in the user's host config, not the upstream module:

- Hostname, hibernation resume UUIDs, LUKS device names
- `mine.*` module enables (asusctl, bluetooth, kde, llama-cpp, etc.)
- KWin / plasma-manager configuration (refresh rate, VRR policy, touchpad
  per-device tweaks like `tapToClick=false`, scale factor)
- Personal tooling (llama-cpp / ollama / Steam / hyprland / etc.)
- `services.libinput.touchpad.{naturalScrolling,tapping,disableWhileTyping}` —
  user preference, not hardware quirk
- TTM page limit / GTT sizing — workload-specific (this user runs LLMs)
- Network / firewall / hostname / IPv6
- The MT7925 BT kernel patch (transient regression, not a long-lived hardware
  quirk)
- Anything under `mine.*`, `home-manager.*`, `programs.plasma.*`

## Proposed upstream layout

Following the existing `asus/flow/gv302x` pattern:

```
asus/
  flow/
    gz302ea/
      default.nix       — main module, imports shared.nix and amdgpu.nix
      shared.nix        — touchpad/keyboard/wifi/usb4/sleep policy
      amdgpu.nix        — DCN 3.5.1 display fixes (opt-in/out options)
      README.md         — link to the canonical sources cited above
```

The `default.nix` should:

- Import `common/cpu/amd`, `common/cpu/amd/pstate.nix`, `common/gpu/amd`,
  `common/pc/laptop`, `common/pc/ssd`
- Import `./shared.nix` and `./amdgpu.nix`
- Set `services.asusd.enable = mkDefault true` (asusctl handles RGB/hotkeys
  after `hid_asus` blacklist)
- Set `hardware.sensor.iio.enable = mkDefault true` (2-in-1 auto-rotation)

The `shared.nix` should:

- Apply `boot.blacklistedKernelModules = [ "hid_asus" ]`
- Install the udev hwdb file for touchpad integration override
- Install the udev rule for `LIBINPUT_IGNORE_DEVICE` on the dock Mouse
- Install the USB4 D3cold / power-control udev rules
- Set `boot.kernelModules = [ "mt7925e" ]` and the modprobe `disable_aspm=1`
- Set `systemd.sleep.settings.Sleep.SuspendState = "freeze"`
- Add `iommu=pt` and `amd_pstate=guided` to `boot.kernelParams`

The `amdgpu.nix` should expose the DCN 3.5.1 options described in section B
above, with sensible defaults that turn ON the stability fixes (because they
are fixes, not behaviour changes, on this hardware).

## Migration in this flake after upstreaming

Once the module is merged, the goldenball host config gets a one-line import:

```nix
imports = [ inputs.hardware.nixosModules.asus-rog-flow-z13-2025 ];
```

And the entire kernel-params block, blacklist, hwdb file, USB4 udev rules,
and MT7925 modprobe options get deleted from `hosts/goldenball/configuration.nix`.
Rough estimate: ~120 lines removed, replaced with ~5.

## Implementation prompt for Qwen3.6-27B

Feed this to a coding model with read access to:

- This flake at `~/git/nixos-r6t/`
- The nixos-hardware repo (clone or fetch via gh CLI)

```
You are creating an upstream contribution to nixos-hardware for the ASUS ROG
Flow Z13 (2025, model GZ302EA). All hardware-specific fixes have been
validated on real hardware running NixOS-unstable; your job is to package them
as a clean nixos-hardware module following the existing conventions.

REFERENCE MATERIALS:
- Source flake (where the validated fixes live): ~/git/nixos-r6t/
  - hosts/goldenball/configuration.nix — the canonical source
  - hosts/z13-hardware.md — the plan (this document) with categorized fixes,
    sources, and rationale
  - modules/nixos/bluetooth/default.nix — DO NOT include the MT7925 BT
    kernel patch in the upstream module; it's a transient regression
- Reference nixos-hardware module: asus/flow/gv302x/ in
  https://github.com/NixOS/nixos-hardware (clone first or fetch from raw.githubusercontent.com)

OUTPUT:
Create a new directory asus/flow/gz302ea/ in your local clone of
nixos-hardware with three files:

1. default.nix
2. shared.nix
3. amdgpu.nix
4. README.md

Use lib.mkDefault liberally so the module is overridable. Use lib.mkMerge for
clarity when combining conditional blocks. Match the formatting style of
gv302x/ exactly (2-space indent, attribute-set-per-line with trailing
commas, mkOption with description strings).

CONSTRAINTS:
- DO NOT include any of the items listed in "What does NOT belong in
  nixos-hardware" in z13-hardware.md.
- DO NOT include the MT7925 BT kernel patch (transient regression).
- DO NOT include hibernation resume UUID, hostname, or any user-specific
  config.
- DO NOT include kernel patches at all in the upstream module.
- DO include all items in sections A through F of z13-hardware.md.
- Each kernel param, udev rule, and module option MUST have a comment
  explaining why it exists, citing the source from z13-hardware.md.
- The amdgpu options follow the gv302x/amdgpu/default.nix idiom
  (mkEnableOption with descriptive default, conditional on the option).

VERIFICATION:
After writing the files, run:
  cd ~/path/to/your-nixos-hardware-clone
  nix-instantiate --parse asus/flow/gz302ea/default.nix
  nix-instantiate --parse asus/flow/gz302ea/shared.nix
  nix-instantiate --parse asus/flow/gz302ea/amdgpu.nix
to check that they parse cleanly. Then construct a minimal test config that
imports the new module and confirm it evaluates without error.

DELIVERABLE:
Print the four file contents in order, each preceded by its path. Then print
a single git commit message in the form:
  asus: add Flow Z13 (2025) GZ302EA support

  Adds Strix Halo / RDNA 3.5 (DCN 3.5.1) display stability workarounds,
  detachable dock touchpad palm-rejection fixes (hid_asus blacklist + udev
  hwdb integration override + LIBINPUT_IGNORE_DEVICE for spurious Mouse
  subdevice), MT7925 wifi modprobe options, and USB4 PCIe / Intel hub
  power management rules.

  Validated on BIOS GZ302EA.311 with kernel 7.0.8 and Mesa 26.1.0.
```

## After upstreaming

1. Open a PR to nixos-hardware with the four files above and the commit
   message.
2. Once merged, bump `inputs.hardware` in flake.nix.
3. Replace the inline workarounds in `hosts/goldenball/configuration.nix`
   with `imports = [ inputs.hardware.nixosModules.asus-rog-flow-z13-2025 ];`
   (or whatever attribute name the maintainers approve).
4. Delete `hosts/z13-hardware.md` (this document) once the migration is
   complete — or keep it as historical context with a header noting it has
   been superseded.
