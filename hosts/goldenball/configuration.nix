{ pkgs, lib, userConfig, ... }:
let
  localLlm = import ./llm-config.nix;
in
{
  imports = [
    ./hardware-configuration.nix
    ../../modules/nixos/asusctl/options.nix
    ../../modules/nixos/asusctl/config.nix
    ../../modules/nixos/llama-cpp/options.nix
    ../../modules/nixos/llama-cpp/config.nix
  ];

  # ---------------------------------------------------------------------------
  # ASUS ROG Z13 AI Max 395 (GZ302) — Strix Halo
  # Hardware: AMD Ryzen AI MAX+ 395 (RDNA 3.5 / gfx1151), MediaTek MT7925 WiFi
  # Role: workstation + local LLM (ROCmFP4 primary, Vulkan fallback, on-demand)
  # ---------------------------------------------------------------------------

  # GZ302EA detachable keyboard dock (USB, 0B05:1A30) and tablet body (0B05:18C6).
  #
  # TWO GOALS in tension:
  #   1. Keyboard backlight brightness control (Fn keys + KDE slider / UPower)
  #      Requires hid_asus to claim 18C6 (tablet N-KEY) → creates
  #      /sys/class/leds/asus::kbd_backlight for UPower/KDE and asusctl leds.
  #   2. Touchpad palm rejection on the dock (1A30)
  #      Requires hid-multitouch to claim 1A30.0004 (the touchpad interface)
  #      with full ABS_MT axes. hid_asus claims it without proper MT axes,
  #      breaking libinput palm detection.
  #
  # SOLUTION: allow hid_asus to load (not blacklisted), but use a udev rule to
  # immediately rebind the touchpad interface (0003:0B05:1A30.0004) from
  # hid_asus to hid-multitouch after hid_asus claims it.
  #
  # Device map (confirmed via /proc/bus/input/devices + sysfs):
  #   0003:0B05:18C6.0006-.0007  tablet N-KEY keyboard  → hid_asus (kbd_backlight)
  #   0003:0B05:1A30.0001-.0003  dock keyboard/media/RF  → hid_asus (fine as-is)
  #   0003:0B05:1A30.0004        dock touchpad           → hid-multitouch (rebind)
  #   0003:0B05:1A30.0005        dock misc               → hid_asus (fine as-is)
  #
  # Source: r/FlowZ13 NixOS user k7_u (2025-05): original blacklist approach.
  # Linux Mint Forums: https://forums.linuxmint.com/viewtopic.php?t=422004

  # Force ID_INPUT_TOUCHPAD_INTEGRATION=internal on the dock touchpad via udev hwdb.
  # systemd's 65-integration.rules sets the property to "external" because the dock's
  # USB port is "removable" (the keyboard physically detaches). libinput then refuses
  # to pair it with the laptop keyboard for DWT, since DWT only pairs internal devices.
  # The hwdb lookup runs in 70-touchpad.rules AFTER 65-integration.rules and overrides
  # whatever ID_INTEGRATION set, per the comment in 65-integration.rules.
  #
  # Format: `touchpad:<bus>:v<vid>p<pid>:name:<name>:*` with vid/pid lowercase 4-digit hex.
  # Reference: /lib/udev/hwdb.d/70-touchpad.hwdb in the systemd source tree.
  services.udev.packages = [
    (pkgs.writeTextFile {
      name = "61-gz302ea-touchpad-internal";
      destination = "/etc/udev/hwdb.d/61-gz302ea-touchpad-internal.hwdb";
      text = ''
        # ASUS ROG Flow Z13 GZ302EA detachable keyboard dock touchpad.
        # Mark as internal so libinput pairs it with the keyboard for disable-while-typing.
        touchpad:usb:v0b05p1a30:*
         ID_INPUT_TOUCHPAD_INTEGRATION=internal
      '';
    })
    (pkgs.writeTextFile {
      name = "79-goldenball-usb4-pm-rules";
      destination = "/etc/udev/rules.d/79-goldenball-usb4-pm.rules";
      text = ''
        # Strix Halo PCIe USB4 bridge roots. Must not runtime-suspend or all
        # downstream Thunderbolt/USB4 PCIe devices can disconnect.
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x150a", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x150a", ATTR{d3cold_allowed}="0"

        # Strix Halo USB4 host routers expose DPIA adapters used by the docked
        # display path. Keep them awake to avoid USB4/display cascade failures.
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158d", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158d", ATTR{d3cold_allowed}="0"
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158e", ATTR{power/control}="on"
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158e", ATTR{d3cold_allowed}="0"

        # Intel PCIe switches inside the dock/enclosure must not enter D3cold;
        # hotplugged downstream devices have failed to wake behind them.
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x0b26", ATTR{d3cold_allowed}="0"
        ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15ef", ATTR{d3cold_allowed}="0"
      '';
    })
  ];

  boot = {
    # linuxPackages_testing (7.2-rc2 at the current flake.lock pin) instead of
    # linuxPackages_latest (7.1.x): the flip_done root-cause fix and several
    # other Strix Halo display/USB4 fixes are only in 7.2-rc. The 7.2-rc tree
    # already contains: the ISM dc_lock deadlock fix, "Restore periodic
    # detection for DCN35" (HPD-bounce-then-IPS display loss, drm/amd#5318),
    # the thunderbolt USB4 CM robustness series (router-ready verification,
    # longer notification timeouts, DP tunnel retry), and the CRTC color
    # management revert that KWin 6.7.1 also works around.
    # Switch back to linuxPackages_latest once 7.2 final lands there.
    kernelPackages = lib.mkDefault pkgs.linuxPackages_testing;

    # Upstream fixes merged in 7.2-rc4 (all Cc: stable), vendored until the
    # nixpkgs testing kernel catches up. Verified to apply cleanly on
    # 7.2-rc2 and 7.2-rc3. When nixpkgs testing reaches 7.2-rc4+ these are
    # already contained and the build will fail loudly with "previously
    # applied" — delete this block and hosts/goldenball/patches/ then.
    #   0001+0002: Leo Li's flip_done root-cause fix — DPG/GSL power gating
    #     masks VSTARTUP/GRPH_PFLIP interrupts on self-refresh eDP at idle
    #     transitions; events are never delivered and atomic commits time
    #     out ("flip_done timed out"). Moves vblank/flip delivery onto the
    #     never-masked VUPDATE_NO_LOCK interrupt. drm/amd#4141.
    #   0003: revert of the 5s vblank offdelay workaround, superseded by
    #     0001/0002 (same Cc: stable chain).
    #   0004: device link making xHCI D0 depend on the APU display device —
    #     fixes the boot/resume "xhci HC died" USB4 cascade (bugzilla
    #     221073, validated on a GZ302EA BIOS 311).
    #   0005: cursor-mode fix for atomic commits that disable a CRTC
    #     (dock hotplug adds/removes crtc-1 here).
    kernelPatches = [
      {
        name = "drm-amd-display-consolidate-dcn-vblank-flip-onto-vupdate-no-lock";
        patch = ./patches/0001-drm-amd-display-consolidate-dcn-vblank-flip-onto-vupdate-no-lock.patch;
      }
      {
        name = "drm-amd-display-check-grph-flip-status-before-sending-event";
        patch = ./patches/0002-drm-amd-display-check-grph-flip-status-before-sending-event.patch;
      }
      {
        name = "revert-drm-amd-display-restore-5s-vbl-offdelay-for-nv3x-dgpus";
        patch = ./patches/0003-revert-drm-amd-display-restore-5s-vbl-offdelay-for-nv3x-dgpus.patch;
      }
      {
        name = "drm-amd-create-device-link-between-apu-display-and-xhci";
        patch = ./patches/0004-drm-amd-create-device-link-between-apu-display-and-xhci.patch;
      }
      {
        name = "drm-amd-display-set-native-cursor-mode-for-disabled-crtcs";
        patch = ./patches/0005-drm-amd-display-set-native-cursor-mode-for-disabled-crtcs.patch;
      }
    ];

    # Encrypted swap backing boot.resumeDevice and swapDevices in hardware-configuration.nix.
    initrd.luks.devices."luks-4c181c40-b517-4477-b5b2-ddb63e56e552".device = "/dev/disk/by-uuid/4c181c40-b517-4477-b5b2-ddb63e56e552";

    # Bring KMS up in stage 1 so amdgpu owns the display engine before the
    # Thunderbolt/USB4 DP tunnel is created. The dock-at-boot failure path is a
    # DP resource allocation race; early KMS is the least invasive ordering test.
    initrd.kernelModules = [ "amdgpu" ];

    kernelParams = [
      # AMD Strix Halo (DCN 3.5.1) display engine workarounds — see thorough notes
      # below. These prevent the page-flip timeout / system freeze that hits on
      # fullscreen VRR gameplay (Rocket League under KWin direct-scanout reproduces
      # the bug reliably). Without them, kwin_wayland logs "Pageflip timed out!
      # This is a bug in the amdgpu kernel driver" until the display engine wedges
      # the whole system. Documented at:
      #   - Arch wiki §6.11 (recommends dcdebugmask=0x10|0x12 for flip_done timeout)
      #   - th3cavalry/strix-halo-linux-setup
      #   - r/FlowZ13 "pageflip timed out" thread
      #   - drm/amd issue #4141 (the flip_done family; root-caused Jun 2026,
      #     fixed by the vendored vupdate_no_lock patches above)
      #   (#4707 was cited here previously but is a dGPU VRAM-clock/FreeSync
      #   issue on RX 6600-class cards — irrelevant to Strix Halo.)

      # ppfeaturemask: default minus three bits.
      #   - GFXOFF      (0x8000)  — prevents microstutter on high-refresh externals
      #   - STUTTER_MODE (0x20000) — same family, also disabled by dcdebugmask 0x002
      #   - OVERDRIVE   (0x4000)  — meaningless on a soldered iGPU and has documented
      #     bad interaction with VRR's MCLK transitions. Removing it also silences
      #     the "Overdrive is enabled, please disable it before reporting any bugs"
      #     warning in dmesg.
      # 0xffff7fff is the kernel default; mask off the three above to reach 0xfff73fff.
      "amdgpu.ppfeaturemask=0xfff73fff"

      # dcdebugmask: disable PSR + PSR-SU + Panel Replay + Stutter + MPO + Pipe Split
      # + dynamic IPS for DCN 3.5.1. Bit values verified against the DC_DEBUG_MASK
      # enum in drivers/gpu/drm/amd/include/amd_shared.h (identical in v7.1 and
      # master as of Jul 2026):
      #   0x001  = DC_DISABLE_PIPE_SPLIT
      #   0x002  = DC_DISABLE_STUTTER     (DRAM stutter low-power mode)
      #   0x010  = DC_DISABLE_PSR        (Panel Self-Refresh v1 and PSR-SU)
      #   0x040  = DC_DISABLE_MPO        (Multi-Plane Overlay)
      #   0x200  = DC_DISABLE_PSR_SU     (PSR Selective Update)
      #   0x400  = DC_DISABLE_REPLAY     (Panel Replay — drm/amd#5519 confirms a
      #            7.0/7.1 eDP wedge on DCN 3.5 fixed only by this bit; keep it
      #            set on any 7.x kernel)
      #   0x1000 = DC_DISABLE_IPS_DYNAMIC (all IPS off except during suspend.
      #            NOT the MPO bit — an earlier comment here decoded 0x1000 as
      #            DC_DISABLE_MPO, which is wrong; MPO is 0x40 and was never
      #            actually disabled before Jul 22 2026. Kept over the stricter
      #            0x800/DC_DISABLE_IPS because always-off IPS breaks s2idle on
      #            GZ302 per th3cavalry/strix-halo-linux-setup PR #170.)
      # Sum = 0x1653 (was 0x1613; +0x40 adds the kernel-level MPO disable that
      # the config always intended — KWIN_DRM_NO_OVERLAY=1 only covers KWin).
      # These are mitigations; the root-cause flip_done fix is the vendored
      # vupdate_no_lock kernel patch pair above.
      "amdgpu.dcdebugmask=0x1653"

      # Disable scatter-gather display on this APU. Strix Halo's iGPU shares system
      # RAM via GTT for display surfaces; sg_display=1 (default) hits a class of
      # DMA-fence flip timeouts. th3cavalry's stable Z13 profile sets this to 0.
      "amdgpu.sg_display=0"

      # Keep CWSR disabled even when amdgpu loads in the initrd for early KMS.
      # boot.extraModprobeConfig below is retained as a stage-2/manual modprobe
      # fallback, but initrd module parameters must be present on the kernel cmdline.
      "amdgpu.cwsr_enable=0"

      # Soft-reset the display engine on timeout instead of hard-locking. Without
      # this the page-flip timeout cascades to a full system freeze; with it,
      # amdgpu can usually recover the display block.
      "amdgpu.gpu_recovery=1"

      # Disable panel adaptive brightness (causes timing issues on external displays)
      "amdgpu.abmlevel=0"

      # Hard-disable FreeSync video / VRR support at the kernel level.
      # Previous mitigations in KWin (VrrPolicy=0) were insufficient; disabling it
      # here prevents the driver from exposing the capability entirely.
      "amdgpu.freesync_video=0"

      # Disable GPU PCIe Link Power Management (ASPM). Transitions between L0/L1
      # states can trigger timing-sensitive hangs in the display engine.
      "amdgpu.aspm=0"

      # Temporarily disable PCIe ASPM globally as a diagnostic. The USB4 root
      # link at 00:01.2 still dropped with amdgpu.aspm=0 and all USB4 root/host-
      # router power pins active, then logged an inconsistent common-clock
      # configuration while re-enumerating. This can increase idle power use and
      # reduce battery life even when USB4 is unplugged.
      # TODO: If this prevents the cascade, replace it with a USB4-scoped
      # mitigation instead of leaving global ASPM disabled.
      "pcie_aspm=off"

      # Disable PCIe port runtime power management. Unlike pcie_aspm=off (link
      # L-state policy), this prevents hotplug/root ports from runtime-suspending
      # tunneled USB4 PCIe devices into D3cold. Needed after ixgbe probed the
      # USB4 X520 before boltd authorization completed and failed D3cold->D0.
      "pcie_port_pm=off"

      # Force native PCIe hotplug services and allow bridge resource reallocation
      # for USB4/TB PCIe tunnels. Without these, hotplugged TB devices authorize
      # but the downstream PCIe tree may never materialize on Strix Halo.
      "pcie_ports=native"
      "pci=realloc"

      # Disable USB4/Thunderbolt CLx lane low-power states. The kernel enables
      # CL0s/CL1/CL2 after router enumeration; on this Strix Halo + TB chain,
      # authorized devices can still fail to establish a downstream PCIe tree.
      "thunderbolt.clx=0"

      # Steam's CHTTPClientThre can generate thousands of split-lock/bus-lock
      # traps during Rocket League sessions. The bus locks are still userspace
      # bugs, but kernel split-lock detection adds #DB/logging overhead that
      # correlates with severe stutter before amdgpu's DCN page-flip timeout.
      "split_lock_detect=off"

      # IOMMU passthrough: zero-cost translation for GPU compute while keeping
      # IOMMU active for USB4 PCIe tunneling and device isolation.
      "iommu=pt"

      # GPU-accessible system RAM limit (shared with OS, not reserved).
      # 104 GB ceiling for large LLM inference; leaves 24 GB for OS/KDE/browsers.
      # 27262976 = 104 GB / 4 KB page size.
      "ttm.pages_limit=27262976"

      "amd_pstate=guided"

      # Hibernation resume target (encrypted swap — update UUID after install)
      "resume=UUID=189690e7-6c8a-47ac-a378-a1a99ed87e3b"
    ];

    # Device used for resume from hibernation
    resumeDevice = "/dev/disk/by-uuid/189690e7-6c8a-47ac-a378-a1a99ed87e3b";

    # MediaTek MT7925 Wi-Fi: load driver at boot to survive cold boots after
    # failed s2idle resume; disable ASPM for stability.
    kernelModules = [ "mt7925e" ];
    extraModprobeConfig = ''
      options mt7925e disable_aspm=1
      # cwsr_enable=0: disable Compute Wavefront Save-Restore in the amdgpu kernel
      # module (not a Vulkan/userspace setting — amdgpu owns the display engine and
      # GPU hardware regardless of which Vulkan driver is used in userspace).
      # Prevents GPU hangs from register file sync issues on Strix Halo (RDNA 3.5 /
      # gfx1151) in 2025-2026 kernels. Reported by th3cavalry/strix-halo-linux-setup
      # and corroborated by r/FlowZ13 silent-freeze reports. Low risk: CWSR is only
      # needed for ROCm compute checkpoint/restore, not for display or gaming.
      options amdgpu cwsr_enable=0
    '';
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      # ROCm OpenCL ICD — used by darktable, blender (CL), and other GPU compute
      # apps. Independent of HIP/ROCm-runtime which segfaults on gfx1151; the
      # OpenCL stack via clr.icd works fine on Strix Halo.
      rocmPackages.clr.icd
      rocmPackages.clr
    ];
  };

  # ROCm symlink for AI/LLM tooling. llama-cpp's active ROCmFP4 fork carries its
  # own runtime closure, but desktop tools such as darktable/blender discover
  # ROCm/OpenCL through this conventional path.
  systemd = {
    tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
      # Manually-quantized GGUFs (e.g. ROCmFP4 STRIX_LEAN) live here. Owned by
      # r6t:users 0755 so scripts/quantize-rocmfp4-strix.fish can write the
      # output without sudo, and the DynamicUser=true llama-cpp.service can
      # still read --model paths inside (world-traversable + world-readable).
      # Cannot use /var/cache/llama-cpp/ for this: that's systemd's
      # CacheDirectory under DynamicUser, mode 0700 dynamic-UID, unreachable
      # from outside the service namespace.
      "d /var/lib/llama-cpp-models 0755 r6t users -"
    ];

    # ASUS Battery Care: keep the almost-always-plugged tablet at 80% max
    # charge. asusctl persists the limit in asusd's config; the sysfs write is
    # a direct kernel fallback for the current boot.
    services.goldenball-battery-charge-limit = {
      description = "Limit ASUS battery charge to 80%";
      wantedBy = [ "multi-user.target" ];
      wants = [ "asusd.service" ];
      after = [ "asusd.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        if ! ${pkgs.asusctl}/bin/asusctl battery limit 80; then
          printf 'asusctl battery limit failed; falling back to sysfs\n' >&2
        fi

        found=0
        for threshold in /sys/class/power_supply/BAT*/charge_control_end_threshold; do
          if [ -w "$threshold" ]; then
            printf '80\n' > "$threshold"
            found=1
          fi
        done

        if [ "$found" -eq 0 ]; then
          printf 'No writable charge_control_end_threshold found under /sys/class/power_supply/BAT*\n' >&2
          exit 1
        fi
      '';
    };

    # services.llama-cpp from nixpkgs always installs with WantedBy=multi-user.target.
    # Override to prevent auto-start at boot — use `systemctl start llama-cpp` or the
    # KDE app menu / panel launcher instead.
    services.llama-cpp.wantedBy = lib.mkForce [ ];
  };

  # GZ302EA dock: ignore phantom REL Mouse subdevice from hid_asus. The dock
  # exposes both a Mouse and a Touchpad; the Mouse bypasses libinput DWT
  # suppression. Ignoring it is safe — ABS_MT Touchpad handles all cursor
  # movement. Upstream libinput issue #1103 / #1283.
  #
  # GZ302EA dock touchpad: rebind hid_asus → hid-multitouch for proper ABS_MT
  # axes. hid_asus claims 0003:0B05:1A30.0004 without proper MT axes, breaking
  # palm rejection. The RUN unbind/bind restores hid-multitouch on that
  # interface. See device map comment at top of file.
  services = {
    udev.extraRules = ''
      SUBSYSTEM=="input", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="1a30", ENV{ID_INPUT_MOUSE}=="1", ENV{ID_INPUT_TOUCHPAD}!="1", ENV{LIBINPUT_IGNORE_DEVICE}="1"

      ACTION=="add", SUBSYSTEM=="hid", KERNELS=="0003:0B05:1A30.0004", DRIVER=="hid_asus", \
        RUN{builtin}="kmod load hid-multitouch", \
        RUN+="/bin/sh -c 'echo 0003:0B05:1A30.0004 > /sys/bus/hid/drivers/hid_asus/unbind && echo 0003:0B05:1A30.0004 > /sys/bus/hid/drivers/hid-multitouch/bind'"
    '';

    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        disableWhileTyping = true;
      };
    };

    # Strix Halo only supports S0 (s2idle) and S4 (hibernate) — no S3 deep sleep.
    # s2idle is unreliable on battery. On AC: stay in s2idle so the machine
    # remains reachable. On battery: lid close triggers suspend only, no hibernate.
    # NOTE: KDE PowerDevil (modules/home/kde-apps) enforces its own sleep policy
    # via whenSleepingEnter. These logind settings are a fallback (pre-login,
    # PowerDevil crash). Keep both in sync.
    logind.settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  environment.sessionVariables = {
    # Disable KWin hardware overlays. MPO (Multi-Plane Overlays) on DCN 3.5.1
    # is a primary trigger for page-flip timeouts. This environment variable
    # acts as a userspace complement to the amdgpu.dcdebugmask=0x1653 kernel
    # param (whose 0x40 bit is the real DC_DISABLE_MPO).
    KWIN_DRM_NO_OVERLAY = "1";
  };

  networking = {
    enableIPv6 = false;
    hostName = "goldenball";
    # MT7925 still has poor power-save behavior on Strix Halo in community
    # reports. Keep scan MAC randomization, but do not let NetworkManager put
    # the Wi-Fi device into powersave during active sessions.
    networkmanager.wifi.powersave = false;
    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 8443 22000 ];
    };
  };

  system.stateVersion = "25.05";

  # ---------------------------------------------------------------------------
  # Modules
  # ---------------------------------------------------------------------------

  mine = {
    home = {
      kde-apps = {
        tablet = true;
        # 2560x1600 panel — 1.5x is the right Xwayland HiDPI scale (module default is 2 for 4K).
        xwaylandScale = 1.5;
        # Pin the llama-cpp start/stop toggle to the panel task manager.
        # Requires the llama-cpp host config (which provides the script + polkit rule).
        llamaCppLauncher = true;
      };
      nixvim = {
        enableSopsSecrets = true;
        enableHaMcp = true;
        # opencode points at the local llama-server on goldenball.
        # Service starts on demand (not at boot) — start with:
        #   systemctl start llama-cpp
        opencode-llamacpp = {
          enable = true;
          # Local llama-server on goldenball (start manually: systemctl start llama-cpp).
          # opencode will use the local server when it's running; it falls back
          # to "model not available" when the service is stopped.
          baseURL = "http://127.0.0.1:8080/v1";
          models = {
            # Model id must match what llama-server reports at /v1/models.
            # Verify: curl -s http://127.0.0.1:8080/v1/models | jq '.data[].id'
            # For ROCmFP4 presets this is the `--alias` value; for HF-fetched
            # presets it's the `hfRepo`. localLlm.activeModel.modelId
            # abstracts both.
            "${localLlm.activeModel.modelId}" = {
              name = "Qwen3.6 35B-A3B MTP (goldenball)";
              context = localLlm.activeModel.contextSize;
              output = 32768;
              variants = {
                # Cycle variants with variant_cycle keybind in opencode.
                thinking.chat_template_kwargs = { enable_thinking = true; };
              };
            };
          };
        };
      };
    };

    asusctl = {
      # GZ302EA has two aura USB devices:
      #   1a30 — detachable keyboard dock (drives keyboard backlight)
      #   18c6 — tablet body (drives the back-panel window light)
      # Written as read-only Nix store symlinks; asusd cannot overwrite at runtime.
      # The 18c6 device has power_zones: [r#None] in aura_support.ron — no separate
      # power-off zone exists for the window light; colour black + brightness Off
      # is the correct way to disable it.
      auraConfigs = {
        "1a30" = ''
          (
              config_name: "aura_1a30.ron",
              brightness: High,
              current_mode: Static,
              builtins: {
                  Static: (
                      mode: Static,
                      zone: r#None,
                      colour1: (r: 255, g: 255, b: 255,),
                      colour2: (r: 0, g: 0, b: 0,),
                      speed: Med,
                      direction: Right,
                  ),
                  Breathe: (
                      mode: Breathe,
                      zone: r#None,
                      colour1: (r: 255, g: 255, b: 255,),
                      colour2: (r: 0, g: 0, b: 0,),
                      speed: Med,
                      direction: Right,
                  ),
                  Pulse: (
                      mode: Pulse,
                      zone: r#None,
                      colour1: (r: 255, g: 255, b: 255,),
                      colour2: (r: 0, g: 0, b: 0,),
                      speed: Med,
                      direction: Right,
                  ),
              },
              multizone_on: false,
              enabled: (
                  states: [
                      (
                          zone: Keyboard,
                          boot: true,
                          awake: true,
                          sleep: true,
                          shutdown: true,
                      ),
                  ],
              ),
          )
        '';
        "18c6" = ''
          (
              config_name: "aura_18c6.ron",
              brightness: Off,
              current_mode: Static,
              builtins: {
                  Static: (
                      mode: Static,
                      zone: r#None,
                      colour1: (r: 0, g: 0, b: 0,),
                      colour2: (r: 0, g: 0, b: 0,),
                      speed: Med,
                      direction: Right,
                  ),
                  Breathe: (
                      mode: Breathe,
                      zone: r#None,
                      colour1: (r: 0, g: 0, b: 0,),
                      colour2: (r: 0, g: 0, b: 0,),
                      speed: Med,
                      direction: Right,
                  ),
                  Pulse: (
                      mode: Pulse,
                      zone: r#None,
                      colour1: (r: 0, g: 0, b: 0,),
                      colour2: (r: 0, g: 0, b: 0,),
                      speed: Med,
                      direction: Right,
                  ),
              },
              multizone_on: false,
              enabled: (
                  states: [
                      (
                          zone: Keyboard,
                          boot: false,
                          awake: false,
                          sleep: false,
                          shutdown: false,
                      ),
                  ],
              ),
          )
        '';
      };
    };
    kde.tablet = true;

    # Local llama-server — ROCmFP4 primary backend for Radeon 8060S (gfx1151).
    # GPU LLM inference. Two backends configured here:
    #   - rocmfp4 = true:  charlie12345/rocmfp4-llama fork — HIP+Vulkan combined
    #     binary with custom Q4_0_ROCMFP4_STRIX{,_LEAN} quants. Reports 80-104
    #     tok/s decode on Qwen3.6-35B-A3B-MTP at 262K context (~2× the stock
    #     Vulkan number). Requires a one-time quantization step:
    #         ./scripts/quantize-rocmfp4-strix.fish --profile lean
    #     Stock ROCm on gfx1151 was historically unstable but the fork's HIP
    #     code path is reported stable on Strix Halo as of 2026-05.
    #   - vulkan = true:   pkgs.llama-cpp-vulkan via RADV. Stable historical
    #     baseline. Use this when the rocmfp4 build breaks or you want to A/B
    #     compare against the ROCmFP4 numbers.
    # Pick one (mutually exclusive). Active model is set via
    # localLlm.activeModel in hosts/goldenball/llm-config.nix.
    #
    # Service is defined but NOT started at boot — start on demand:
    #   systemctl start llama-cpp   (loads model into GPU RAM, ~15s)
    #   systemctl stop llama-cpp    (frees GPU RAM for ComfyUI / gaming)
    # The SNI tray daemon (mine.home.kde-apps.llamaCppLauncher = true) registers
    # a system-tray icon alongside wifi/bluetooth/volume for one-click toggle.
    llama-cpp = {
      rocmfp4 = true;
      host = "0.0.0.0";
      port = 8080;
      modelFile = localLlm.activeModel.modelFile or null;
      hfRepo = localLlm.activeModel.hfRepo or null;
      hfFile = localLlm.activeModel.hfFile or null;
      alias = localLlm.activeModel.alias or null;
      contextSize = localLlm.activeModel.contextSize;
      ubatchSize = localLlm.activeModel.ubatchSize or 1024;
      cacheRamMiB = localLlm.activeModel.cacheRamMiB;
      extraFlags = localLlm.activeModel.extraFlags;
    };

    steam = {
      goldenballGameLauncher.enable = true;
    };
    nfs.mounts.photos = {
      device = "crown:/mnt/thunderbay/8TB-C/Pictures";
      mountPoint = "/mnt/thunderbay/8TB-C/Pictures";
    };
  };

  # ---------------------------------------------------------------------------
  # KWin compositor tuning — goldenball-specific (180 Hz eDP, VRR)
  # ---------------------------------------------------------------------------
  # These override / extend the shared kwinrc settings in modules/home/kde-apps.
  # Merged by home-manager's configFile mechanism (plasma-manager overrideConfig).
  home-manager.users.${userConfig.username} = {
    programs.plasma = {
      configFile = {
        # KWin compositor: target the panel's native 180 Hz and keep VRR disabled.
        # MaxFPS / RefreshRate ensure KWin's render loop aims for the correct ceiling;
        # without these the compositor may auto-detect a lower rate after SDDM's
        # first-boot atomic commit failure.
        "kwinrc"."Compositing"."MaxFPS" = 180;
        "kwinrc"."Compositing"."RefreshRate" = 180;

        # VRR policy 0 = Never: fully disable VRR/FreeSync on the eDP panel.
        # Previously set to 1 (Automatic) but DCN 3.5.1 flip_done timeouts still
        # trigger even in Automatic mode — observed Jun 4 2026 within 100s of KWin
        # startup during idle Plasma desktop init (no GPU load, no USB4 dock, no
        # llama-cpp). This is the strongest remaining software mitigation.
        # Trade: loses adaptive sync in games (Rocket League etc. will run at fixed
        # 180 Hz). Set back to 1 if an upstream kernel fix lands for DCN 3.5.1.
        # Re-enabling VRR later also requires changing amdgpu.freesync_video back
        # to 1 so the driver exposes VRR capability to userspace.
        "kwinrc"."Output eDP-1"."VrrPolicy" = 0;

        # plasma-manager's typed touchpad option doesn't expose KDE's
        # DisableEventsOnExternalMouse setting, so write it directly via configFile.
        # Section path matches what plasma-manager generates:
        #   [Libinput][<vid_dec>][<pid_dec>][<name>].
        # 2821 = 0x0B05, 6704 = 0x1A30. Decimal vendor/product IDs are how KDE keys these.
        #
        # TODO: experiment with removing this line once palm rejection is confirmed
        # working from the hwdb integration=internal fix alone. This was added as a
        # speculative extra safety net; the hwdb DWT pairing should be the real cure.
        # Risk of leaving it: if the LIBINPUT_IGNORE_DEVICE udev rule for the dock's
        # phantom REL Mouse subdevice ever fails to match, KDE will treat that phantom
        # as an "external mouse" and disable the touchpad. Removing this setting
        # eliminates that failure mode and lets you use a real external mouse alongside
        # the touchpad simultaneously.
        "kcminputrc"."Libinput/2821/6704/ASUSTeK Computer Inc. GZ302EA-Keyboard Touchpad"."DisableEventsOnExternalMouse" = true;
      };

      # GZ302EA dock touchpad: configure via plasma-manager. tapToClick=false stops
      # palm rests from triggering clicks during typing (the physical buttonpad still
      # clicks normally). naturalScroll matches the user preference. disableWhileTyping
      # is set both here AND system-wide via services.libinput.touchpad.disableWhileTyping
      # to ensure the runtime libinput device config has DWT enabled regardless of which
      # config layer wins.
      #
      # IMPORTANT: DWT only takes effect if libinput considers the touchpad "internal"
      # OR pairable with an internal keyboard. systemd's 65-integration.rules tags this
      # USB dock touchpad as "external" because the keyboard physically detaches; the
      # 61-gz302ea-touchpad-internal.hwdb file above overrides that to "internal" so
      # DWT pairing actually works.
      input.touchpads = [
        {
          name = "ASUSTeK Computer Inc. GZ302EA-Keyboard Touchpad";
          vendorId = "0b05";
          productId = "1a30";
          naturalScroll = true;
          disableWhileTyping = true;
          tapToClick = false;
        }
      ];
    };
  };
}
