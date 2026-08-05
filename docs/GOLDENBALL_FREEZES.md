# goldenball Hard Freeze Troubleshooting

**Device:** ASUS ROG Flow Z13 GZ302EA  
**APU:** AMD Ryzen AI MAX+ 395 (Strix Halo, gfx1151 / RDNA 3.5 / DCN 3.5.1)  
**RAM:** 128 GB LPDDR5X unified (CPU + GPU share the same physical pool)  
**OS:** NixOS unstable, kernel 7.2-rc (`linuxPackages_testing` + vendored patches, since Jul 22 2026), BIOS GZ302EA.311
**Display:** Internal eDP-1 (Tianma TL134ADXP03 2560×1600 IPS, 48–180 Hz — the _internal_ panel was previously mislabeled OLED here and in th3cavalry docs; ASUS spec/Notebookcheck confirm IPS. It is PSR-capable, which is what matters for the freeze mechanism). External: 4K 240 Hz **OLED** desk display via Plugable USB4-HUB3A TB4 dock → DP-4. The flip_done bug has hit **both** displays: eDP-1/crtc-0 (most incidents) and the external OLED on DP-4/crtc-1 (Jun 23 2026)

If a freeze happens again, start a new session and say **"it happened again"** — this doc provides the full context to continue troubleshooting efficiently.

---

## Quick diagnosis checklist for a new freeze

Run these immediately after reboot:

```fish
# 1. Was it the known display bug?
journalctl -b -1 -k --no-pager | grep -E "flip_done|amdgpu.*ERROR|pin framebuffer"

# 2. Was it a USB4/Thunderbolt cascade?
journalctl -b -1 -k --no-pager | grep -E "xhci.*died|HC died|Link Down|d3cold|retimer"

# 3. Was it GPU memory exhaustion?
journalctl -b -1 -k --no-pager | grep -E "vm_validate|Not enough memory|pin failed"

# 4. What was running before the freeze?
journalctl -b -1 --no-pager | tail -80 | grep -v "dbus-broker\|Ignoring dup\|libextest"

# 5. Flip timeout count for the session
journalctl -b -1 --no-pager | grep -c "Pageflip timed"
```

---

## Root cause: DCN 3.5.1 `flip_done timed out` (primary)

**The freeze signature:**

```
kernel: amdgpu 0000:c4:00.0: [drm] *ERROR* [CRTC:416:crtc-0] flip_done timed out
kwin_wayland: Pageflip timed out! This is a bug in the amdgpu kernel driver
```

**What it is:** The DCN 3.5.1 display engine stalls waiting for a page-flip acknowledgement from the GPU hardware. Most observed incidents hit eDP-1 (internal panel, CRTC-0), but Jun 23 2026 confirmed the same class can also hit external DP-4 (CRTC-1). Once triggered it fires every second indefinitely. With `gpu_recovery=1` the system sometimes self-recovers; without recovery it hard-freezes requiring power cycle.

**Originally eDP-1-only in collected logs, but no longer exclusively so.** External display on DP-4 (via Plugable TB4 dock) previously continued working during eDP-1 freezes; Jun 23 showed DP-4 itself can stall as `CRTC:428:crtc-1`.

### Root cause found upstream (Jun–Jul 2026) — fix merged in 7.2-rc4

AMD (Leo Li) root-caused this exact class in drm/amd#4141: on DCN hardware,
the vblank (VSTARTUP) and pageflip-completion (GRPH_PFLIP) interrupts can be
**masked by power-gating** — DPG (dynamic power gating, engages on
self-refresh-capable eDP after enough static frames), GSL (global sync lock
during commit programming), and MALL. When masked, the completion event is
never delivered and the atomic commit times out — exactly `flip_done timed
out`. This matches goldenball's trigger pattern perfectly: every observed
freeze begins at a **transition to idle** (~2 min after llama-cpp finishes,
~100 s after idle login, 5 s after Rocket League exits, shortly after dock
HPD reconfiguration).

The fix consolidates all vblank/flip event delivery onto `VUPDATE_NO_LOCK`,
an interrupt source that is never masked:

- `8382cd234981` "drm/amd/display: consolidate DCN vblank/flip handling onto vupdate_no_lock"
- `48ab86360af1` "drm/amd/display: check GRPH_FLIP status before sending event"
- `f39283eab44f` revert of the interim "5s vbl offdelay" workaround

Merged to mainline 2026-07-17 (drm-fixes-2026-07-18-1, first tag v7.2-rc4),
all Cc: stable, but **not in 7.1.4 or the stable queue as of Jul 22 2026** —
Mario Limonciello said stable backports will be manual. Field reports on the
final revision are positive (a Framework 13 tester went from >1 freeze/day to
zero; another tester's flip timeouts disappeared on a patched 7.1-rc kernel).
Earlier revisions of the series caused regressions (broken alt+tab, cursor
corruption, DMCUB errors) — only the merged mainline pair should be used.

Because the masking happens in hardware/firmware via DPG/GSL, **no
`dcdebugmask` combination fully prevents it** — which is why freezes
continued despite every mitigation below. This also explains why the bits
only reduced frequency.

**Since Jul 22 2026 goldenball runs `linuxPackages_testing` (7.2-rc) with the
fix pair + two more Cc: stable patches vendored in
`hosts/goldenball/patches/` (see `hosts/goldenball/configuration.nix
boot.kernelPatches`).** The extra two: `75c8746b9d0a` (device link forcing
xHCI to resume after the APU display — fixes the boot/resume "xhci HC died"
USB4 cascade, bugzilla 221073, validated on a GZ302EA BIOS 311) and
`cea54c52d82d` (cursor mode fix for atomic commits disabling a CRTC, relevant
to dock hotplug adding/removing crtc-1). Both verified to apply on 7.2-rc2/rc3.

Also relevant, already contained in 7.2-rc: "Restore periodic detection for
DCN35" (`5cc0f35d83e2` — HPD bounce then IPS entry leaves display
undiscoverable, drm/amd#5318, a Strix Halo report), the ISM dc_lock deadlock
fix, the thunderbolt USB4 connection-manager robustness series (router-ready
verification, 255 ms notification timeout, DP-tunnel retry on bandwidth
change — targets the dock-at-boot "failed to allocate DP resource"
signature), and the CRTC color-management revert (7.1 regression).

Not a hardware defect. Same signature reported across vendors (HP ZBook Ultra
G1a, Framework Desktop/13, GMKtec EVO-X2) and distros (Arch, CachyOS,
Bazzite, Fedora) — switching distros would not have avoided it. The bug has
hit both panel types on this machine — the internal IPS eDP and the external
4K240 OLED behind the USB4/DP tunnel — consistent with a display-engine
(interrupt delivery) bug rather than anything panel-specific.

### Tracking the fix upstream / getting off linuxPackages_testing

`linuxPackages_testing` + vendored patches is a **temporary** state. Track
these five commits; all were merged to mainline 2026-07-17 via tag
`drm-fixes-2026-07-18-1` (first release tag **v7.2-rc4**) and all carry
`Cc: stable`:

| Vendored patch                      | Upstream commit | First mainline tag |
| ----------------------------------- | --------------- | ------------------ |
| 0001 vupdate_no_lock consolidation  | `8382cd234981`  | v7.2-rc4           |
| 0002 GRPH_FLIP status check         | `48ab86360af1`  | v7.2-rc4           |
| 0003 revert 5s vbl offdelay         | `f39283eab44f`  | v7.2-rc4           |
| 0004 xHCI/APU-display device link   | `75c8746b9d0a`  | v7.2-rc4           |
| 0005 cursor mode for disabled CRTCs | `cea54c52d82d`  | v7.2-rc4           |

**Step 1 — drop the vendored patches** once nixpkgs `linuxPackages_testing`
reaches 7.2-rc4 or later. Check after each flake input bump:

```fish
nix eval .#nixosConfigurations.goldenball.config.boot.kernelPackages.kernel.version
```

The build itself is also a tripwire: `patch` fails loudly on already-applied
hunks, so a testing bump to ≥ rc4 will break the build until the
`boot.kernelPatches` block in `hosts/goldenball/configuration.nix` and the
`hosts/goldenball/patches/` directory are deleted.

**Step 2 — return to `linuxPackages_latest`** once 7.2 final is the stable
kernel there (7.2 final expected ~Aug 2026; nixpkgs usually promotes it to
`linuxPackages_latest` within days). Verify before switching:

```fish
# what latest would be, from the flake's pinned nixpkgs
nix eval --raw --impure --expr '(import (builtins.getFlake "/home/r6t/git/nixos-r6t").inputs.nixpkgs { system = "x86_64-linux"; }).linuxPackages_latest.kernel.version'
```

If it reports `7.2` or higher: flip `kernelPackages` back to
`pkgs.linuxPackages_latest` and remove the testing rationale comment.

**Do NOT drop back to 7.1.y early.** Even when the flip_done pair reaches a
7.1.y point release (watch the stable queue, below), 7.1.y will still lack
the DCN35 periodic-detection fix, the ISM deadlock fix, the thunderbolt USB4
CM series, and the color-management revert. 7.2 is the settling point.

To check whether the stable backports have landed (informational only):

```fish
# any release's changelog — bump the version number as releases appear
curl -s https://cdn.kernel.org/pub/linux/kernel/v7.x/ChangeLog-7.1.5 | grep -iE "vupdate_no_lock|GRPH_FLIP|device link between APU"
# or the pending stable queue
curl -s https://git.kernel.org/pub/scm/linux/kernel/git/stable/stable-queue.git/plain/queue-7.1/series | grep -iE "vupdate|grph|apu"
```

**Verification on the running system** (any kernel):

```fish
uname -r                                      # expect 7.2-rc2+ while on testing
sudo cat /sys/kernel/debug/dri/*/amdgpu_dm_ips_status | grep "IPS config"   # expect 5 (DISABLE_DYNAMIC) with dcdebugmask 0x1653
journalctl -b -k --no-pager | grep "DMUB hardware initialized"              # record DMUB fw version for regression tracking
```

**Success criteria for declaring the bug fixed on goldenball:** several weeks
spanning the historical trigger set with zero `flip_done` events — llama-cpp
runs followed by idle, Rocket League/gamescope sessions with the 4K240 OLED
docked, dock hotplugs, dock-at-boot, and multi-day uptimes. Then start
peeling back mitigations one at a time (candidates in rough order:
`cwsr_enable=0` removal, narrowing `dcdebugmask` toward the community
baseline `0x600`, re-enabling VRR via `freesync_video=1` + KWin
`VrrPolicy=1`, `pcie_aspm=off` removal for battery life) — one change per
reboot cycle, with a week of observation each.

### Confirmed triggers

| Trigger                                                                                                   | Evidence                                                                                                                                                                                 |
| --------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `VrrPolicy=2` (Always) in KWin — compositor issues adaptive-sync flips on desktop                         | Flips started within 90s of login with Steam open, before any game launched                                                                                                              |
| Heavy Vulkan compute (MTP inference) followed by idle — display engine transitions out of peak-load state | Freeze consistently ~2 min after llama-cpp finishes generating                                                                                                                           |
| USB4/TB4 dock connected + PCIe link instability → DPIA path disruption → flip timeout ~1h later           | Jun 2 2026: xhci died at 21:11, flip_done at 22:09                                                                                                                                       |
| USB4/TB4 dock hotplug without a PCIe link failure                                                         | Jun 15 2026: eDP froze 22s after display HPD, while external DP-4 survived                                                                                                               |
| USB4/TB4 dock boot-time cascade + external 4K240 DP-4                                                     | Jun 23 2026: xhci died at 17:58:51, DP-4 HPD at 17:58:59, crtc-1 flip_done at 18:17:28                                                                                                   |
| Rocket League under gamescope on external 4K240 after USB4 boot cascade                                   | Jun 28 2026: xhci died/re-enumerated at boot, Rocket League exited at 14:44:01, KWin page-flip timeouts began at 14:44:06, crtc-0 flip_done at 14:44:14                                  |
| Rocket League under gamescope on internal 180 Hz panel, no external display                               | Jul 18 2026: gamescope switched to 180 Hz on eDP; ~8K Steam `CHTTPClientThre` split-lock traps preceded stutter; KWin page-flip timeouts began at 15:15:17, crtc-0 flip_done at 15:15:18 |
| `VrrPolicy=1` (Automatic) does NOT fully prevent it                                                       | Still occurred with Automatic mode + external display connected                                                                                                                          |
| Idle Plasma desktop startup (~100s after KWin start, no GPU load)                                         | Jun 4 2026: flip_done at 18:46:24, boot at 18:44:14, no llama-cpp/USB4/dock                                                                                                              |
| Heavy ROCmFP4 compute + idle on external display — no USB4 cascade                                        | Jul 16 2026: crtc-1 flip_done at 15:49:37; gpu_recovery=1 recovered display; llama-cpp ~133K ctx prefill; clean DCN 3.5.1 timeout, no link-down                                          |

### Mitigations in place (as of Jul 22 2026)

Display/boot settings in `hosts/goldenball/configuration.nix`:

| Setting                     | Value                   | Purpose                                                                                              |
| --------------------------- | ----------------------- | ---------------------------------------------------------------------------------------------------- |
| `boot.kernelPackages`       | `linuxPackages_testing` | 7.2-rc: carries the flip_done root-cause fix + USB4/thunderbolt fixes (see above)                    |
| `boot.kernelPatches`        | 5 vendored              | vupdate_no_lock pair + offdelay revert + xHCI device link + cursor fix (`hosts/goldenball/patches/`) |
| `amdgpu.dcdebugmask`        | `0x1653`                | pipe split, stutter, PSR, **MPO (0x40)**, PSR-SU, replay, dynamic IPS (0x1000)                       |
| `amdgpu.sg_display`         | `0`                     | Disables scatter-gather display (DMA-fence flip timeouts on unified memory)                          |
| `amdgpu.gpu_recovery`       | `1`                     | Soft-resets display engine on timeout instead of hard-locking                                        |
| `amdgpu.ppfeaturemask`      | `0xfff73fff`            | Disables GFXOFF, STUTTER_MODE, OVERDRIVE                                                             |
| `amdgpu.freesync_video`     | `0`                     | Hard-disables VRR capability in the kernel                                                           |
| `amdgpu.aspm`               | `0`                     | Disables GPU PCIe ASPM only; does not affect the USB4 PCIe tree                                      |
| `amdgpu.abmlevel`           | `0`                     | Disables adaptive backlight management                                                               |
| `amdgpu.cwsr_enable`        | `0`                     | Disables Compute Wavefront Save-Restore; cmdline copy is required now that amdgpu loads in initrd    |
| `boot.initrd.kernelModules` | `amdgpu`                | Enables early KMS so amdgpu initializes before Thunderbolt/USB4 DP tunnel creation                   |
| `split_lock_detect`         | `off`                   | Disables x86 split-lock detection overhead after Steam/Rocket League generated thousands of traps    |

**dcdebugmask decode correction (Jul 22 2026):** the config previously
documented `0x1000` as `DC_DISABLE_MPO`. Verified against the `DC_DEBUG_MASK`
enum in `drivers/gpu/drm/amd/include/amd_shared.h` (identical in v7.1 and
master): `0x1000` is `DC_DISABLE_IPS_DYNAMIC` (IPS off except during
suspend); MPO is `0x40` and was **never actually disabled** at the kernel
level before Jul 22 (only KWin-level via `KWIN_DRM_NO_OVERLAY=1`). The mask
was changed `0x1613 → 0x1653` to add the real MPO bit. The accidental
`0x1000` was kept: dynamic-IPS-off is the right IPS mode here anyway — the
stricter `0x800` (`DC_DISABLE_IPS`, always off, wins precedence per the enum
docs) breaks s2idle on GZ302 per th3cavalry PR #170, and community data
(th3cavalry issue #166) shows IPS-heavy masks like `0xe12` correlating with
flip_done freezes on 7.x rather than preventing them. Note the community
baseline for GZ302 is now the much narrower `0x600`; goldenball deliberately
keeps the broader mask until the fixed kernel proves itself, then bits can be
peeled back one at a time. IPS state is observable live at
`/sys/kernel/debug/dri/0/amdgpu_dm_ips_status`.

**cwsr_enable=0 caveat:** AMD's Mario Limonciello warned (Framework 16 LG/TB
thread, Jan 2026) that disabling CWSR blocks GPU preemption and can itself
cause issues; the gfx1151 CWSR bugs it worked around were fixed in kernel
6.18.4. Candidate for removal once the 7.2-rc kernel is proven stable —
change one variable at a time.

KWin: `VrrPolicy=0` (Never — VRR fully disabled, changed Jun 4 2026 after VrrPolicy=1 still triggered).
KWin overlays: disabled with `KWIN_DRM_NO_OVERLAY=1`.
Goldenball Steam gamescope launcher: nested gamescope profiles cap the game refresh to 180 Hz to preserve the tablet panel's native refresh while avoiding the observed 4K240 gamescope path.

**These reduce frequency but do not eliminate the bug.**
**`amdgpu.gpu_recovery=1` has been unreliable since Jul 16 2026** — the soft-reset fails to recover the display in the majority of cases. When it does recover (Jul 16 15:49), the display is immediately re-frozen; when it fails (Jul 16 15:49), the display stays locked indefinitely.

### Jun 15 2026: dock hotplug directly triggered an eDP-only stall

At 12:35:17 the Plugable USB4-HUB3A began a normal enumeration. DP hotplug reached
amdgpu at 12:35:19, KWin page-flip timeouts began at 12:35:41, and CRTC-0 logged
`flip_done timed out` at 12:35:50. The internal eDP-1 image hard-locked, but the
external DP-4 display, browser video, terminal, and rest of the host continued
working.

Unlike the Jun 2 and Jun 13 incidents, there was no `Link Down`, `HC died`,
device removal, AER error, ENOMEM, or framebuffer pin failure. The dock's PCIe
tree remained present. The `62:00.0` and `62:04.0` unused Goshen Ridge bridge
ports logged `Unable to change power state from D3cold to D0`, but both remained
runtime-suspended and had `d3cold_allowed=0`; there is no evidence those warnings
represent a root USB4 link collapse. All configured amdgpu mitigations and
`pcie_aspm=off` were active.

This establishes clean dock/display hotplug itself as a trigger for the primary
DCN 3.5.1 eDP bug, independent of the secondary USB4 PCIe cascade.

### Jun 23 2026: external DP-4 / CRTC-1 stalled

At boot, the Plugable USB4 chain had a full PCIe/USB4 cascade: `0000:00:01.1` link
down, retimers disconnected, `xhci_hcd 0000:52:00.0` logged `HC died`, then the
dock re-enumerated. DP hotplug reached amdgpu at 17:58:59 (`DMUB HPD IRQ
callback: link_index=5`). About 18.5 minutes later, KWin began logging
`Pageflip timed out!`, and the kernel logged:

```
amdgpu 0000:c4:00.0: [drm] *ERROR* [CRTC:428:crtc-1] flip_done timed out
```

This time the visible hard-frozen output was the external DP-4 display, not the
internal eDP panel. `kscreen-doctor -o` still reported DP-4 connected/enabled at
3840x2160@240 with VRR disabled, and `/sys/class/drm/card1-DP-4/status` remained
`connected`, so this was a display pipeline stall rather than unplug detection.
There was no fresh USB4 link-down event immediately before the 18:17 timeout;
the only nearby userspace event was a PowerDevil backlight helper around
18:16:51-18:17:02. No ENOMEM / framebuffer pin failure was observed in the
collected log slice.

This disproves the earlier eDP-only assumption. Hypothesis: the boot-time USB4
cascade left the DP tunnel/display engine in a fragile state, and the external
4K240 DP-4 scanout later hit the same DCN 3.5.1 page-flip failure path.

### Jul 16 2026: CRTC-1 flip_done — gpu_recovery=1 did NOT recover

At 15:49:37, `CRTC:428:crtc-1` logged `flip_done timed out` — same CRTC as the
Jun 23 incident. **`gpu_recovery=1` failed to recover.** No soft-reset sequence
was logged, no recovery attempt was detected. The display remained frozen
indefinitely. The system continued running (llama-cpp processing at ~254 tok/s),
but the display never recovered.

This demonstrates that `gpu_recovery=1` is **unreliable** on this hardware —
the display engine can hard-fail from flip_done timeouts with no recovery path.
A reboot is required to restore the display.

### Jul 18 2026: Rocket League on internal eDP, no external display

Rocket League launched under gamescope on the built-in Z13 panel only. Gamescope
selected RADV STRIX_HALO and changed the Wayland backend to 180 Hz. There was no
nearby USB4 DisplayPort tunnel failure, no `Link Down`, no `HC died`, no MCE/EDAC,
no thermal fault, no NVMe/EXT4 error, no OOM kill, no `amdgpu_vm_validate`, no
framebuffer pin failure, and no GPU ring timeout before the display failure.

The user-visible symptom was a long stutter fest before shutdown. The broad
signal that differs from most prior investigations is a Steam `CHTTPClientThre`
split-lock/bus-lock storm: 8190 kernel split-lock messages in the boot, firing
for roughly 20 minutes before the fatal display timeout. KWin page-flip timeouts
began at 15:15:17, followed by:

```
15:15:18 amdgpu 0000:c4:00.0: [drm] *ERROR* [CRTC:424:crtc-0] flip_done timed out
15:15:52 amdgpu 0000:c4:00.0: [drm] *ERROR* [CRTC:424:crtc-0] commit wait timed out
15:16:02 amdgpu 0000:c4:00.0: [drm] *ERROR* [PLANE:421:plane-7] commit wait timed out
15:16:03 amdgpu 0000:c4:00.0: [drm] vblank wait timed out on crtc 0
```

Steam then segfaulted in multiple `CHTTPClientThre` threads and KDE initiated a
normal poweroff request (`.plasma-shutdow`), so the journal ends in a clean
`systemd-poweroff` rather than a silent full-machine lock.

Interpretation: the final display failure is still the primary DCN 3.5.1 CRTC-0
page-flip/vblank stall, now confirmed on the internal panel without any external
display dependency. The prolonged pre-failure stutter is plausibly from Steam's
split-lock storm, not USB4 or thermal/storage/memory failure. Added
`split_lock_detect=off` as a diagnostic mitigation to remove kernel split-lock
detection overhead; the userspace bus locks themselves may still be costly.

Follow-up: ArchWiki documents a Steam-launched nested gamescope "Lag Bomb" where
heavy stutter starts after roughly 24 minutes, with ValveSoftware/gamescope#163
as the upstream reference. `goldenball-steam-profile` now isolates gamescope from
Steam's `LD_PRELOAD` hooks while preserving them for the game process. For Rocket
League, prefer the native launcher profiles first; use the gamescope profiles
only as an A/B test or when resolution spoofing/upscaling is needed.

### Jun 28 2026: Rocket League / gamescope after USB4 boot cascade

At boot, all configured mitigations were active on kernel 7.1.0:
`amdgpu.dcdebugmask=0x1613`, `amdgpu.sg_display=0`, `amdgpu.gpu_recovery=1`,
`amdgpu.ppfeaturemask=0xfff73fff`, `amdgpu.freesync_video=0`,
`amdgpu.aspm=0`, `pcie_aspm=off`, `pcie_port_pm=off`, `pcie_ports=native`,
`pci=realloc`, and `thunderbolt.clx=0`.

The Plugable USB4 chain had another boot-time cascade: `00:01.2` linked down at
14:14:57, both retimers disconnected, the DM7801 device disconnected, and
`xhci_hcd 0000:b2:00.0` logged `Controller not ready at resume -19` plus
`HC died; cleaning up`. The dock re-enumerated at 14:15:05 and amdgpu logged a
DP hotplug callback (`DMUB HPD IRQ callback: link_index=8`).

Rocket League launched through gamescope 3.16.24 at 14:18:31 using RADV
`AMD Radeon 8060S Graphics (RADV STRIX_HALO)`. Gamescope switched the Wayland
backend to 240 Hz at 14:18:39. User-visible sequence: Rocket League began
stuttering on the external display, then the internal display froze, then the
external display froze too.

At 14:44:00-14:44:01, `gamescopereaper` aborted in `gamemode_request_end` /
D-Bus cleanup, gamescope logged `Primary child shut down`, and Steam stopped
game 252950. Five seconds later KWin began logging `Pageflip timed out! This is
a bug in the amdgpu kernel driver`. The kernel then logged:

```
14:44:14 amdgpu 0000:c4:00.0: [drm] *ERROR* [CRTC:424:crtc-0] flip_done timed out
14:44:18 amdgpu 0000:c4:00.0: [drm] *ERROR* [CRTC:424:crtc-0] hw_done or flip_done timed out
14:44:39 amdgpu 0000:c4:00.0: [drm] *ERROR* [CRTC:424:crtc-0] commit wait timed out
14:44:49 amdgpu 0000:c4:00.0: [drm] *ERROR* [PLANE:421:plane-7] commit wait timed out
14:44:50 amdgpu 0000:c4:00.0: [drm] vblank wait timed out on crtc 0
```

No `amdgpu_vm_validate`, framebuffer pin failure, ENOMEM, GPU reset, RAS/MCE,
or thermal fault was observed in the prior boot. There were frequent Steam
`CHTTPClientThre` split-lock bus-lock traps in the minute before the crash;
these may explain user-visible stutter but are not sufficient to explain the
amdgpu CRTC/vblank stall.

Interpretation: this is the primary DCN 3.5.1 display pipeline bug again, not a
new hardware failure. The boot-time USB4 cascade is a plausible precondition as
in the Jun 23 DP-4 incident, but this time the fatal kernel timeout landed on
`crtc-0` while Rocket League/gamescope was active on the external 4K240 output.
The gamescope/GameMode coredumps are recorded as nearby userspace events, not
as the proven root cause of the display-engine stall.

### Next steps if freezes continue

1. ~~Try `VrrPolicy=0` (Never)~~ **Done Jun 4 2026** — VRR fully disabled; loses adaptive sync in games
2. ~~Check if any upstream kernel patch for DCN 3.5.1 flip_done has landed~~ **Done Jul 22 2026** — root-cause fix found (drm/amd#4141, merged 7.2-rc4); goldenball moved to `linuxPackages_testing` + vendored patches. See "Root cause found upstream" above.
3. Test Rocket League with `goldenball-steam-profile native-16x10-1920x1200 -- %command%` first. If it still stutters/freezes, retry the gamescope profile with the `LD_PRELOAD` workaround now built into `goldenball-steam-profile`; `goldenball-steam-profile gamescope-*` now also uses `--nested-refresh 180`, so observe whether the Rocket League/gamescope path still wedges after a USB4 boot cascade.
4. **If a freeze recurs on the patched 7.2-rc kernel:** capture and report upstream on drm/amd#4244 (active GZ302EA thread with a near-identical Jul 21 2026 report) referencing #4141. Capture over SSH while wedged:
   - `dmesg` (full), plus `journalctl -b -k`
   - `cat /sys/kernel/debug/dri/*/amdgpu_dm_dmub_tracebuffer` (Leo Li collects these)
   - `cat /sys/kernel/debug/dri/*/amdgpu_firmware_info` (DMUB version line matters — it's a live variable in this bug family)
   - `cat /sys/kernel/debug/dri/*/amdgpu_dm_ips_status`
   - Watch for the secondary signature `dc_dmub_srv_log_diagnostic_data: DMCUB error` — one tester still hits it with the patches on 7.0.13.
5. **Check historical/new boot logs for `optc35_disable_crtc` REG_WAIT timeouts** (`journalctl -k | grep -E "optc35|REG_WAIT"`). drm/amd#5138/#5155 document a "zombie CRTC" variant where a failed CRTC teardown at display-path reconfiguration deadlocks `flip_done` on the _other_ CRTC minutes-to-hours later — the closest structural match for the dock-hotplug-then-freeze cases, and NOT fixed by the vupdate_no_lock series. If present, report on #5155.
6. **DMUB firmware watch:** nixos-unstable's linux-firmware 20260622 ships DMUB 0.1.64.0 for DCN 3.5.1; 0.1.65.0–0.1.67.0 exist in linux-firmware git only (0.1.67.0, 2026-07-17: "Improve lock mechanism with HW lock mgr" — squarely in the flip/lock problem space, part of a year-long series of APU HW-lock fixes). If freezes persist on the fixed kernel, overriding linux-firmware to a git snapshot is the next lever. Counterpoint: one Z13 user _fixed_ their freeze by _reverting_ a DMUB update (linux-firmware c092c7487eb7), so record `dmesg | grep "DMUB hardware initialized"` before/after any firmware change.
7. If the USB4-cascade preconditions persist (with the xHCI device-link patch they shouldn't): experiment with `thunderbolt.host_reset=0` (skips boot-time USB4 router reset, preserving firmware-created tunnels; suggested by AMD for AMD platforms) and `thunderbolt.bw_alloc_mode=0` (reduced disconnect frequency for a ZBook Ultra G1a reporter in drm/amd#4961). Also worth trying: dock on the _other_ USB4-C port — the two ports have different PD controllers and drm/amd#5131 showed one port working while the other was wedged.
8. Upstream issues to watch: #4141 (fix thread), #4244 (GZ302EA), #5155/#5138 (zombie CRTC), #4961 (spurious DMUB HPD tears down TB4 tunnel), #5131 (DPIA dead after transient PCIe link drop — "more like a platform issue" per AMD), #5011 (DP tunnel initially negotiates 2 lanes; staged modeset workaround), bugzilla 221073 (xHCI resume race; fixed by vendored patch 0004, but a rarer separate hard-hang remains open there).

---

## Secondary failure: USB4/Thunderbolt PCIe cascade (Plugable TB4 dock)

**Signature:**

```
kernel: pcieport 0000:00:01.1: pciehp: Slot(0): Link Down
kernel: pcieport 0000:00:01.1: pciehp: Slot(0): Card not present
kernel: xhci_hcd 0000:52:00.0: Controller not ready at resume -19
kernel: xhci_hcd 0000:52:00.0: HC died; cleaning up
kernel: ixgbe 0000:44:00.1: Adapter removed
```

**What it is:** One of the USB4 PCIe bridges at `0000:00:01.1` or `0000:00:01.2` (1022:150a, "Strix Halo PCIe USB4 Bridge") drops its link. Everything downstream dies: the dock's xhci USB controller, the ixgbe NIC. The display engine then loses its DPIA-routed display path, and a flip_done timeout follows.

**Observed:**

- Jun 2 2026 at 21:11 after 3+ day uptime. No prior sleep events that day. Flip timeout followed about 58 min later.
- Jun 13 2026 at 16:15 on `00:01.2`, 22 min after attaching the dock. The root link, retimers, Titan Ridge xHCI, and ixgbe NICs disappeared; the tree re-enumerated 22 sec later. KWin page-flip timeouts began 90 sec after recovery and the eDP CRTC-0 `flip_done` timeout followed at 16:17:25. There was no system suspend. Re-enumeration logged `ASPM: current common clock configuration is inconsistent`.

### Mitigations in place

Udev rules in `hosts/goldenball/configuration.nix` plus X520 function rules in
`modules/nixos/usb4-sfp/default.nix`:

```
1022:150a  power/control=on, d3cold_allowed=0   (USB4 PCIe bridge root)
1022:158d  power/control=on, d3cold_allowed=0   (USB4 host router)
1022:158e  power/control=on, d3cold_allowed=0   (USB4 host router)
8086:0b26  d3cold_allowed=0                     (Intel PCIe switch in dock)
8086:15ef  d3cold_allowed=0                     (Intel PCIe switch in dock)
```

**The `d3cold_allowed=0` on 158d/158e was added Jun 2026** (previously only `power/control=on` was set for those two). The 150a pin is goldenball-specific and lives in an ordered host udev rule; the X520/82599 function pins live in the shared `usb4-sfp` module.

Kernel params in `hosts/goldenball/configuration.nix` for the same USB4/TB PCIe tunnel:

```
pcie_port_pm=off
pcie_ports=native
pci=realloc
thunderbolt.clx=0
```

`thunderbolt.clx=0` fixed the Jun 2026 hotplug failure where `boltctl` showed the dock/enclosure authorized but `lspci` never showed the downstream PCIe tree or ixgbe NIC.

### Related: external display missing when dock is attached at boot

**Symptom:** With the Plugable dock connected at boot, the external display is
absent at SDDM/Plasma. Other dock devices can work. Unplugging/replugging the
dock later causes the external display to appear.

**Current signature:** the USB4/TB chain enumerates, but the DisplayPort tunnel
fails before userspace sees the external output:

```
thunderbolt 0000:c6:00.6: 0:6 <-> 2:13 (DP): not active, tearing down
thunderbolt 0000:c6:00.6: 0: failed to allocate DP resource for port 7
sddm-greeter-qt6: Adding view for "eDP-1" ...
```

After replug, the chain drops/re-enumerates and amdgpu receives hotplug:

```
thunderbolt 1-0:2.1: retimer disconnected
pcieport 0000:00:01.2: pciehp: Slot(0-1): Link Down
xhci_hcd 0000:b2:00.0: HC died; cleaning up
amdgpu 0000:c4:00.0: [drm] DMUB HPD IRQ callback: link_index=8
```

Observed on multiple kernel 7.1 boots with different NixOS system generations
(Jun 23 and Jun 28). `kscreen-doctor -o` after replug reports the display as
`DP-7` connected/enabled at 3840x2160@240.

**Interpretation:** this is a USB4 DisplayPort tunnel/resource allocation race,
not a generic dock failure. It explains why USB/PCIe devices on the dock can be
usable while the external display is missing. The boot-time DP tunnel failure is
also a plausible precondition for later `flip_done` stalls, because the display
pipeline starts from a fragile re-enumerated state.

**Next config tests, one at a time:**

1. ~~If no Thunderbolt dock device is needed before root unlock/login, remove
   `thunderbolt` from `boot.initrd.availableKernelModules` for goldenball so the
   dock is not enumerated in stage 1.~~ **Failed Jun 28 2026** — caused loss of
   keyboard input at the LUKS prompt even with the native keyboard. Do not retry
   without a separate initrd input fix.
2. ~~If delaying Thunderbolt is not acceptable, test early amdgpu KMS instead by
   adding `amdgpu` to `boot.initrd.kernelModules`, so the display engine is up
   before the Thunderbolt DP tunnel is created.~~ **Config changed Jul 22 2026** — observe whether dock-at-boot DP allocation failures or later flip timeouts decrease.
3. **Partially addressed by the Jul 22 2026 kernel move:** 7.2-rc contains
   `afe9021d63b4` "thunderbolt: Improve multi-display DisplayPort tunnel
   allocation" — the driver now retries DP tunnels it previously dropped
   ("not active, tearing down" → forgotten until replug), plus the USB4 CM
   robustness series (router-ready check, 255 ms notification timeout).
   Observe whether dock-at-boot display absence still occurs on 7.2-rc.
4. If it persists: test `thunderbolt.host_reset=0` (see "Next steps" item 7).
5. If neither helps, test a deliberate post-boot Thunderbolt reauthorization or
   controller power-cycle service, but only with user approval because it will
   briefly disconnect every device on the dock.

### Next steps if TB cascade recurs

1. Check `journalctl -b -1 -k | grep "Jun.*21:1"` for what preceded the link drop
2. Test `pcie_aspm=off` kernel param (added to config Jun 13; aggressive, but eliminates PCIe ASPM as a cause)
3. Consider whether `SuspendState=s2idle` (current) is stable with TB4 dock; may need to disconnect dock before sleep

---

## Secondary failure: GPU memory exhaustion (ENOMEM)

**Signature:**

```
kernel: amdgpu 0000:c4:00.0: [drm] *ERROR* amdgpu_vm_validate() failed.
kernel: amdgpu 0000:c4:00.0: [drm] *ERROR* Not enough memory for command submission!
kernel: [drm:amdgpu_dm_plane_helper_prepare_fb] *ERROR* Failed to pin framebuffer with error -12
```

**What it is:** The GPU virtual address space ran out during a command submission while llama-cpp was active. `-12 = ENOMEM`. The display framebuffer couldn't be pinned in GTT/VRAM, causing display corruption or freeze.

**Observed:** May 30 2026 at 20:25 during llama-cpp inference, and again May 31 during dock hotplug.

**Note:** On Strix Halo unified memory, `amdgpu_vm_validate` errors do NOT mean physical RAM ran out — the 35B model only uses ~29 GB of the 104 GB GPU-accessible pool. This is a GPU virtual address space management issue under RADV pressure.

### Mitigation in place

`RADV_PERFTEST=nogttspill` in `modules/nixos/llama-cpp/config.nix` environment (Vulkan-capable path). Prevents RADV from spilling GPU buffer allocations between pools under perceived pressure. Was accidentally removed in commit `60a9423` (May 30 2026) and restored the same day.

---

## llama-cpp configuration for this hardware

See `hosts/goldenball/llm-config.nix` for the authoritative config.

**Key hardware differences from typical Strix Halo docs** (which assume 64 GB):

- 128 GB unified RAM → ~104 GB visible to GPU via TTM (`ttm.pages_limit=27262976`)
- ROCmFP4 backend (HIP+Vulkan combined binary) for the active 35B-MTP model
- ~256 GB/s LPDDR5X bandwidth (memory clock fixed at 1000 MHz)

**Active model as of Jun 2026:** ROCmFP4 STRIX_LEAN (`Qwen3.6-35B-A3B-MTP-ROCmFP4-STRIX_LEAN.gguf`)

- Context: 262144 (256K), quantized Q4_0_ROCMFP4_STRIX_LEAN (~19 GB)
- MTP speculative decoding: `--spec-type draft-mtp --spec-draft-n-max 3`, `--reasoning on`
- ubatch: 512 (reduced from 1024 to give DCN 3.5.1 more idle windows between MTP bursts)
- Backend: ROCmFP4 fork, ROCm0 device
- Measured decode: ~50-71 tok/s with 56-80% draft acceptance (avg ~65%)
- **Note:** Performance is ~50% below the fork's published numbers (80-104 tok/s) due to
  lower draft acceptance, host environment differences, and the 256 GB/s bandwidth ceiling.
  See `docs/LLM-HOSTING-TUNING.md` for full benchmark analysis.

**Known llama-cpp warnings to ignore:**

- `n_ctx_seq < n_ctx_train` — using less than max trained context, normal
- `cache_reuse is not supported by this context` — hybrid GDN attention, expected
- `forcing full prompt re-processing` — hybrid GDN, expected every turn

**Warning that indicates a config bug:**

- `DEPRECATED: argument '-ub' specified multiple times` → `-ub` appears in both `ubatchSize` option AND `extraFlags`; remove `-ub` from `extraFlags`, use `ubatchSize` field in `llm-config.nix`

---

## WiFi: MAC randomization (partially solved)

**Problem:** MT7925 WiFi was using random MACs per-connection attempt. AP rejected reconnection attempts with `Reason: 9 = STA_REQ_ASSOC_WITHOUT_AUTH` (deauth loop).

**Fix:** `networking.networkmanager.wifi.macAddress = "stable-ssid"` in `modules/nixos/networkmanager/default.nix`. Generates a stable hash per SSID — AP always sees the same client MAC for a given network. SSIDs are never stored in the flake (live in NM keyfiles outside the repo).

**Additional goldenball stability setting (Jul 22 2026):** `networking.networkmanager.wifi.powersave = false` in `hosts/goldenball/configuration.nix`, matching Strix Halo community guidance to keep MT7925 out of NetworkManager powersave during active sessions.

**Known issue (Jun 2026):** The global `[connection]` default in `NetworkManager.conf` only applies to new connections. Existing connections created before this setting was added may still use random MACs despite the global config being correct. Verified: <ssid> connection has `cloned-mac-address` empty (should fall back to global `stable-ssid`), but NM 1.56 still generates different MACs per attempt. Fix per-connection:

```fish
nmcli connection modify <SSID> 802-11-wireless.cloned-mac-address stable-ssid
```

---

## Hardware vs software verdict

**All confirmed freeze modes are software/firmware bugs:**

| Symptom                          | Root cause                                                                   | Hardware? |
| -------------------------------- | ---------------------------------------------------------------------------- | --------- |
| `flip_done timed out` → freeze   | DCN interrupt masking by power gating; fixed upstream 7.2-rc4 (drm/amd#4141) | No        |
| USB4 PCIe link drops → xhci dies | xHCI/amdgpu resume race; fixed upstream (bugzilla 221073, vendored patch)    | No        |
| ENOMEM GPU command submission    | RADV memory pressure under MTP inference                                     | No        |
| WiFi fails to join known network | NM MAC randomization breaking re-association                                 | No        |

**NixOS vs other distros (assessed Jul 22 2026):** the same flip_done class is
reported on Arch, CachyOS, Bazzite, and Fedora, and on other Strix Halo
hardware (HP ZBook Ultra G1a, Framework Desktop, GMKtec EVO-X2). CachyOS/
Bazzite carry no private fix for it — their advantage was only kernel/firmware
cadence, which NixOS unstable matches (nixpkgs had 7.2-rc in
`linuxPackages_testing` before most distros shipped it). Switching distro
would not have avoided this bug; staying on NixOS with the vendored patches
gets the fix earlier than any stable distro kernel.

No evidence of hardware defect in any collected logs (no MCE, no hardware ECC errors, no thermal throttling, no NVMe errors on the installed Corsair P310).

---

## Boot history reference (May–Jun 2026)

| Date         | Notable events                                                                                                                                                                                                                                 |
| ------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| May 23       | Multiple boots on kernel 6.17.8, NixOS 25.05 — zero flip timeouts                                                                                                                                                                              |
| May 24       | Rebuilt to NixOS 26.05 (kernel 7.0.8) + added amdgpu params + VRR — flip timeouts begin                                                                                                                                                        |
| May 29–30    | Multiple flip_done freezes; mitigations added (dcdebugmask 0x612, cwsr=0, VrrPolicy=1)                                                                                                                                                         |
| May 30 19:13 | 3-day boot begins; 35B MTP model loaded; ENOMEM errors appear                                                                                                                                                                                  |
| May 31 10:35 | Plugable dock hotplugged; framebuffer pin failures                                                                                                                                                                                             |
| Jun 2 21:11  | USB4 cascade: PCIe link down, xhci died, ixgbe removed                                                                                                                                                                                         |
| Jun 2 22:09  | flip_done timeout → hard freeze → reboot                                                                                                                                                                                                       |
| Jun 4 18:44  | Boot; flip_done at 18:46:24 (~100s after KWin, idle desktop). VrrPolicy changed 1→0                                                                                                                                                            |
| Jun 9 18:45  | Boot; flip_done at 19:17:32. Occurred with VrrPolicy=0, no dock connected.                                                                                                                                                                     |
| Jun 13 16:15 | USB4 `00:01.2` link dropped and recovered; eDP flip timeout followed at 16:17:25.                                                                                                                                                              |
| Jun 15 12:35 | Dock hotplug completed without link loss; eDP flip timeout followed 31 sec after attach.                                                                                                                                                       |
| Jun 23 18:17 | External DP-4 hard-froze; `CRTC:428:crtc-1` flip_done after boot-time USB4 cascade.                                                                                                                                                            |
| Jun 28 14:44 | Rocket League/gamescope on external 4K240; `CRTC:424:crtc-0` flip_done after USB4 boot cascade.                                                                                                                                                |
| Jun 28 boot  | External display absent at boot; DP tunnel logged `not active` / `failed to allocate DP resource for port 7`; replug produced HPD and `DP-7`.                                                                                                  |
| Jul 16 15:49 | `CRTC:428:crtc-1` flip_done at 15:49:37; gpu_recovery=1 recovered display — no hard freeze. llama-cpp heavy prefill (~133K ctx) at the time. No USB4 cascade.                                                                                  |
| Jul 18 15:15 | Rocket League/gamescope on internal 180 Hz eDP only; ~8K Steam `CHTTPClientThre` split-lock traps preceded stutter; `CRTC:424:crtc-0` flip_done at 15:15:18.                                                                                   |
| Jul 22       | Config: moved to 7.2-rc (`linuxPackages_testing`) + 5 vendored upstream patches (flip_done root-cause fix, xHCI device link, cursor fix); dcdebugmask 0x1613→0x1653 (real MPO bit); early KMS; wifi powersave off; gamescope capped at 180 Hz. |

---

## Files to check when troubleshooting

| File                                          | What's there                                                                                                                                 |
| --------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `hosts/goldenball/configuration.nix`          | All kernel params, kernelPackages/kernelPatches, udev rules, VrrPolicy, auraConfigs, hid_asus udev rebind                                    |
| `hosts/goldenball/patches/`                   | Vendored upstream kernel patches (flip_done fix pair, offdelay revert, xHCI device link, cursor fix) — delete once nixpkgs testing ≥ 7.2-rc4 |
| `hosts/goldenball/hardware-configuration.nix` | Generated initrd module list; currently includes `thunderbolt`                                                                               |
| `hosts/goldenball/llm-config.nix`             | LLM model presets, active model selection                                                                                                    |
| `modules/nixos/llama-cpp/config.nix`          | llama-server service, `RADV_PERFTEST`, `MESA_SHADER_CACHE_DIR`                                                                               |
| `modules/nixos/usb4-sfp/default.nix`          | USB4/TB4 PCIe power pinning for ixgbe NIC                                                                                                    |
| `modules/nixos/networkmanager/default.nix`    | WiFi MAC policy                                                                                                                              |
| `modules/nixos/asusctl/default.nix`           | Aura LED option passthrough                                                                                                                  |
| `docs/LLM-HOSTING-TUNING.md`                  | LLM tuning reference for goldenball and crown                                                                                                |
| `docs/INCUS.md`                               | Container architecture (not directly relevant to freezes)                                                                                    |
