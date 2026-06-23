# goldenball Hard Freeze Troubleshooting

**Device:** ASUS ROG Flow Z13 GZ302EA  
**APU:** AMD Ryzen AI MAX+ 395 (Strix Halo, gfx1151 / RDNA 3.5 / DCN 3.5.1)  
**RAM:** 128 GB LPDDR5X unified (CPU + GPU share the same physical pool)  
**OS:** NixOS unstable, kernel 7.0.x, BIOS GZ302EA.311  
**Display:** Internal eDP-1 (Tianma 2560×1600 OLED, 48–180 Hz); external via Plugable USB4-HUB3A TB4 dock → DP-4

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

**What it is:** The DCN 3.5.1 display engine (eDP-1 internal panel, CRTC-0) stalls waiting for a page-flip acknowledgement from the GPU hardware. Once triggered it fires every second indefinitely. With `gpu_recovery=1` the system sometimes self-recovers; without recovery it hard-freezes requiring power cycle.

**Always affects eDP-1 (internal panel) only.** External display on DP-4 (via Plugable TB4 dock) continues working during the freeze.

**This is a known upstream kernel bug with no fix as of kernel 7.0/7.1-rc5 (May 2026).** The DCN 3.5.x code has not been touched upstream since June 2024. Not a hardware defect.

### Confirmed triggers

| Trigger                                                                                                   | Evidence                                                                    |
| --------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| `VrrPolicy=2` (Always) in KWin — compositor issues adaptive-sync flips on desktop                         | Flips started within 90s of login with Steam open, before any game launched |
| Heavy Vulkan compute (MTP inference) followed by idle — display engine transitions out of peak-load state | Freeze consistently ~2 min after llama-cpp finishes generating              |
| USB4/TB4 dock connected + PCIe link instability → DPIA path disruption → flip timeout ~1h later           | Jun 2 2026: xhci died at 21:11, flip_done at 22:09                          |
| USB4/TB4 dock hotplug without a PCIe link failure                                                         | Jun 15 2026: eDP froze 22s after display HPD, while external DP-4 survived  |
| `VrrPolicy=1` (Automatic) does NOT fully prevent it                                                       | Still occurred with Automatic mode + external display connected             |
| Idle Plasma desktop startup (~100s after KWin start, no GPU load)                                         | Jun 4 2026: flip_done at 18:46:24, boot at 18:44:14, no llama-cpp/USB4/dock |

### Mitigations in place (as of Jun 2026)

All in `hosts/goldenball/configuration.nix` kernel params:

| Param                   | Value          | Purpose                                                                                          |
| ----------------------- | -------------- | ------------------------------------------------------------------------------------------------ |
| `amdgpu.dcdebugmask`    | `0x1613`       | Also disables pipe split and MPO, in addition to stutter, PSR, PSR-SU, and replay                |
| `amdgpu.sg_display`     | `0`            | Disables scatter-gather display (DMA-fence flip timeouts on unified memory)                      |
| `amdgpu.gpu_recovery`   | `1`            | Soft-resets display engine on timeout instead of hard-locking                                    |
| `amdgpu.ppfeaturemask`  | `0xfff73fff`   | Disables GFXOFF, STUTTER_MODE, OVERDRIVE                                                         |
| `amdgpu.freesync_video` | `0`            | Hard-disables VRR capability in the kernel                                                       |
| `amdgpu.aspm`           | `0`            | Disables GPU PCIe ASPM only; does not affect the USB4 PCIe tree                                  |
| `amdgpu.abmlevel`       | `0`            | Disables adaptive backlight management                                                           |
| `amdgpu.cwsr_enable`    | `0` (modprobe) | Disables Compute Wavefront Save-Restore; prevents GPU hangs from register sync issues on gfx1151 |

KWin: `VrrPolicy=0` (Never — VRR fully disabled, changed Jun 4 2026 after VrrPolicy=1 still triggered).
KWin overlays: disabled with `KWIN_DRM_NO_OVERLAY=1`.

**These reduce frequency but do not eliminate the bug.**

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

### Next steps if freezes continue

1. ~~Try `VrrPolicy=0` (Never)~~ **Done Jun 4 2026** — VRR fully disabled; loses adaptive sync in games
2. Check if any upstream kernel patch for DCN 3.5.1 flip_done has landed (search `drm/amd` commits)
3. File upstream at https://gitlab.freedesktop.org/drm/amd/-/issues with `sudo dmesg` output

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

`RADV_PERFTEST=nogttspill` in `modules/nixos/llama-cpp/default.nix` environment (Vulkan path). Prevents RADV from spilling GPU buffer allocations between pools under perceived pressure. Was accidentally removed in commit `60a9423` (May 30 2026) and restored the same day.

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

**Known issue (Jun 2026):** The global `[connection]` default in `NetworkManager.conf` only applies to new connections. Existing connections created before this setting was added may still use random MACs despite the global config being correct. Verified: <ssid> connection has `cloned-mac-address` empty (should fall back to global `stable-ssid`), but NM 1.56 still generates different MACs per attempt. Fix per-connection:

```fish
nmcli connection modify <SSID> 802-11-wireless.cloned-mac-address stable-ssid
```

---

## Hardware vs software verdict

**All confirmed freeze modes are software/firmware bugs:**

| Symptom                          | Root cause                                   | Hardware? |
| -------------------------------- | -------------------------------------------- | --------- |
| `flip_done timed out` → freeze   | DCN 3.5.1 kernel bug, no upstream fix        | No        |
| USB4 PCIe link drops → xhci dies | Strix Halo USB4 power management instability | No        |
| ENOMEM GPU command submission    | RADV memory pressure under MTP inference     | No        |
| WiFi fails to join known network | NM MAC randomization breaking re-association | No        |

No evidence of hardware defect in any collected logs (no MCE, no hardware ECC errors, no thermal throttling, no NVMe errors on the installed Corsair P310).

---

## Boot history reference (May–Jun 2026)

| Date         | Notable events                                                                           |
| ------------ | ---------------------------------------------------------------------------------------- |
| May 23       | Multiple boots on kernel 6.17.8, NixOS 25.05 — zero flip timeouts                        |
| May 24       | Rebuilt to NixOS 26.05 (kernel 7.0.8) + added amdgpu params + VRR — flip timeouts begin  |
| May 29–30    | Multiple flip_done freezes; mitigations added (dcdebugmask 0x612, cwsr=0, VrrPolicy=1)   |
| May 30 19:13 | 3-day boot begins; 35B MTP model loaded; ENOMEM errors appear                            |
| May 31 10:35 | Plugable dock hotplugged; framebuffer pin failures                                       |
| Jun 2 21:11  | USB4 cascade: PCIe link down, xhci died, ixgbe removed                                   |
| Jun 2 22:09  | flip_done timeout → hard freeze → reboot                                                 |
| Jun 4 18:44  | Boot; flip_done at 18:46:24 (~100s after KWin, idle desktop). VrrPolicy changed 1→0      |
| Jun 9 18:45  | Boot; flip_done at 19:17:32. Occurred with VrrPolicy=0, no dock connected.               |
| Jun 13 16:15 | USB4 `00:01.2` link dropped and recovered; eDP flip timeout followed at 16:17:25.        |
| Jun 15 12:35 | Dock hotplug completed without link loss; eDP flip timeout followed 31 sec after attach. |

---

## Files to check when troubleshooting

| File                                       | What's there                                                                      |
| ------------------------------------------ | --------------------------------------------------------------------------------- |
| `hosts/goldenball/configuration.nix`       | All kernel params, udev rules, VrrPolicy, auraConfigs, hid_asus udev rebind       |
| `hosts/goldenball/llm-config.nix`          | LLM model presets, active model selection                                         |
| `modules/nixos/llama-cpp/default.nix`      | llama-server service, `RADV_PERFTEST`, `MESA_SHADER_CACHE_DIR`                    |
| `modules/nixos/usb4-sfp/default.nix`       | USB4/TB4 PCIe power pinning for ixgbe NIC                                         |
| `modules/nixos/networkmanager/default.nix` | WiFi MAC policy                                                                   |
| `modules/nixos/asusctl/default.nix`        | Aura LED option passthrough                                                       |
| `docs/LLM-HOSTING-TUNING.md`               | LLM tuning reference (written for crown/R9700 but applies with noted differences) |
| `docs/INCUS.md`                            | Container architecture (not directly relevant to freezes)                         |
