{ inputs, pkgs, lib, userConfig, ... }:
let
  localLlm = import ./llm-config.nix;
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # ---------------------------------------------------------------------------
  # ASUS ROG Z13 AI Max 395 (GZ302) — Strix Halo
  # Hardware: AMD Ryzen AI MAX+ 395 (RDNA 3.5 / gfx1151), MediaTek MT7925 WiFi
  # Role: workstation + local LLM (vulkan, on-demand)
  # ---------------------------------------------------------------------------

  # GZ302EA detachable keyboard dock (USB, 0B05:1A30) — palm rejection / cursor jumping.
  #
  # ROOT CAUSE: the dock's HID interfaces are claimed by the `hid-asus` kernel driver,
  # which exposes the touchpad without proper multi-touch contact axes (no pressure,
  # no contact size, no width). Without those axes, libinput cannot do palm rejection
  # — palm contacts look identical to finger contacts and move the cursor freely.
  # `hid-asus` also exposes a parallel REL_X/Y "Mouse" subdevice that bypasses DWT.
  #
  # FIX: blacklist `hid_asus` entirely. The dock then enumerates under `hid-multitouch`
  # which exposes the device with proper internal-touchpad characteristics (full ABS_MT
  # axes, INPUT_PROP_BUTTONPAD, integration=internal), restoring palm detection and
  # DWT pairing with the keyboard.
  #
  # Tradeoff: lose ASUS-specific HID functionality (RGB control via hid-asus, some
  # hotkeys). RGB is recoverable via asusctl over the platform driver path.
  #
  # Source: r/FlowZ13 NixOS user k7_u (2025-05): "All other issues were solved by
  # blacklisting hid-asus kernel module" on the Z13 395+.
  # Linux Mint Forums thread: https://forums.linuxmint.com/viewtopic.php?t=422004

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
  ];

  # Suppress the spurious Mouse (REL_X/Y) subdevice. With hid_asus blacklisted this
  # may no longer be exposed at all; if it is, libinput ignores it cleanly.
  # Touchpad (ABS_MT) is unaffected — it handles all cursor movement.
  # Upstream tracking: libinput issue #1103, #1283.

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    # Blacklist hid_asus so the GZ302EA dock falls back to hid-multitouch (full
    # MT axes for proper palm rejection). See touchpad note above.
    blacklistedKernelModules = [ "hid_asus" ];

    initrd.luks.devices."luks-4c181c40-b517-4477-b5b2-ddb63e56e552".device = "/dev/disk/by-uuid/4c181c40-b517-4477-b5b2-ddb63e56e552";

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
      #   - drm/amd issues #4141, #4707

      # ppfeaturemask: default minus three bits.
      #   - GFXOFF      (0x8000)  — prevents microstutter on high-refresh externals
      #   - STUTTER_MODE (0x20000) — same family, also disabled by dcdebugmask 0x002
      #   - OVERDRIVE   (0x4000)  — meaningless on a soldered iGPU and has documented
      #     bad interaction with VRR's MCLK transitions. Removing it also silences
      #     the "Overdrive is enabled, please disable it before reporting any bugs"
      #     warning in dmesg.
      # 0xffff7fff is the kernel default; mask off the three above to reach 0xfff73fff.
      "amdgpu.ppfeaturemask=0xfff73fff"

      # dcdebugmask: disable PSR + PSR-SU + Panel Replay + Stutter for DCN 3.5.1.
      #   0x002 = DC_DISABLE_STUTTER  (DRAM stutter low-power mode)
      #   0x010 = DC_DISABLE_PSR      (Panel Self-Refresh; transitively disables PSR-SU)
      #   0x400 = DC_DISABLE_REPLAY   (Panel Replay — new in DCN 3.5+, broken on Z13)
      # Sum = 0x412. The interaction between PSR-SU/Panel Replay and FreeSync VRR
      # is what races the vblank IRQ and causes the page-flip timeout.
      "amdgpu.dcdebugmask=0x412"

      # Disable scatter-gather display on this APU. Strix Halo's iGPU shares system
      # RAM via GTT for display surfaces; sg_display=1 (default) hits a class of
      # DMA-fence flip timeouts. th3cavalry's stable Z13 profile sets this to 0.
      "amdgpu.sg_display=0"

      # Soft-reset the display engine on timeout instead of hard-locking. Without
      # this the page-flip timeout cascades to a full system freeze; with it,
      # amdgpu can usually recover the display block.
      "amdgpu.gpu_recovery=1"

      # Disable panel adaptive brightness (causes timing issues on external displays)
      "amdgpu.abmlevel=0"

      # Enable FreeSync video / VRR support in the amdgpu DRM driver for the eDP
      # panel (Tianma TL134ADXP03, native 48–180 Hz range). The KWin VRR policy
      # alone is not enough — the kernel driver must also expose VRR capability
      # to userspace. Without freesync_video=1 KWin's VrrPolicy=Always is a no-op.
      # NOTE: this is the canonical way to enable FreeSync on AMD eDP panels.
      # The strix-halo research suggested removing it as redundant on
      # native-FreeSync panels, but on this hardware specifically it is required;
      # KWin's VRR config silently does nothing without it.
      "amdgpu.freesync_video=1"

      # IOMMU passthrough: zero-cost translation for GPU compute while keeping
      # IOMMU active for USB4 PCIe tunneling and device isolation.
      "iommu=pt"

      # GPU-accessible system RAM limit (shared with OS, not reserved).
      # 96 GB ceiling for large LLM inference; leaves 32 GB for OS/KDE/browsers.
      # 25165824 = 96 GB / 4 KB page size.
      "ttm.pages_limit=25165824"

      "amd_pstate=guided"

      # Hibernation resume target (encrypted swap — update UUID after install)
      "resume=UUID=189690e7-6c8a-47ac-a378-a1a99ed87e3b"
    ];

    # Device used for resume from hibernation
    resumeDevice = "/dev/disk/by-uuid/189690e7-6c8a-47ac-a378-a1a99ed87e3b";

    # MediaTek MT7925 Wi-Fi: load driver at boot to survive cold boots after
    # failed s2idle resume; disable ASPM for stability.
    kernelModules = [ "mt7925e" ];
    extraModprobeConfig = "options mt7925e disable_aspm=1";
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

  # ROCm symlink for AI/LLM tooling (darktable / blender CL discover this path).
  # Not used by llama-cpp here — that runs the Vulkan backend.
  systemd = {
    tmpfiles.rules = [
      "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
    ];

    sleep.settings.Sleep = {
      HibernateDelaySec = "30m";
      SuspendState = "freeze";
    };

    # services.llama-cpp from nixpkgs always installs with WantedBy=multi-user.target.
    # Override to prevent auto-start at boot — use `systemctl start llama-cpp` or the
    # KDE app menu / panel launcher instead.
    services.llama-cpp.wantedBy = lib.mkForce [ ];
  };

  # USB4/Thunderbolt display stability: Strix Halo USB4 host routers
  # (1022:158d, 1022:158e) use DPIA adapters that crash ~10 min after boot
  # if the router enters runtime suspend. Intel PCIe switches inside the hub
  # (8086:0b26, 8086:15ef) must not enter D3cold (hotplugged, fail to wake).
  services = {
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158d", ATTR{power/control}="on"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158e", ATTR{power/control}="on"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x0b26", ATTR{d3cold_allowed}="0"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15ef", ATTR{d3cold_allowed}="0"

      # GZ302EA dock (0B05:1A30): tell libinput to ignore the spurious Mouse (REL_X/Y)
      # subdevice. The dock exposes both a Mouse and a Touchpad from the same HID
      # interface. DWT does not apply to pointer/mouse devices, so palm contact during
      # typing generates REL cursor movement that bypasses all libinput suppression.
      # Ignoring the Mouse node entirely is safe: the Touchpad (ABS_MT) handles all
      # cursor movement correctly. Upstream libinput issue #1103 / #1283.
      SUBSYSTEM=="input", ATTRS{id/vendor}=="0b05", ATTRS{id/product}=="1a30", ENV{ID_INPUT_MOUSE}=="1", ENV{ID_INPUT_TOUCHPAD}!="1", ENV{LIBINPUT_IGNORE_DEVICE}="1"
    '';

    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        disableWhileTyping = true;
      };
    };

    fprintd.enable = false;

    # Strix Halo only supports S0 (s2idle) and S4 (hibernate) — no S3 deep sleep.
    # s2idle is unreliable on battery. On AC: stay in s2idle so the machine
    # remains reachable. On battery: suspend-then-hibernate after 30 min.
    # NOTE: KDE PowerDevil (modules/home/kde-apps) enforces its own sleep policy
    # via whenSleepingEnter. These logind settings are a fallback (pre-login,
    # PowerDevil crash). Keep both in sync.
    logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
      HandleLidSwitchExternalPower = "suspend";
      HandleLidSwitchDocked = "ignore";
    };
  };

  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  networking = {
    enableIPv6 = false;
    hostName = "goldenball";
    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 22 8384 8443 22000 ];
    };
  };

  system.stateVersion = "25.05";
  time.timeZone = "America/Los_Angeles";

  # ---------------------------------------------------------------------------
  # Modules
  # ---------------------------------------------------------------------------

  mine = {
    flatpak = {
      base.enable = true;
      anki.enable = true;
      calibre.enable = true;
      element.enable = true;
      inkscape.enable = true;
      libreoffice.enable = true;
      picard.enable = true;
      proton-mail.enable = true;
      remmina.enable = true;
      zoom.enable = true;
    };

    home = {
      alacritty.enable = true;
      atuin.enable = true;
      bitwarden.enable = true;
      browsers.enable = true;
      darktable.enable = true;
      drawio.enable = true;
      fish.enable = true;
      fontconfig.enable = true;
      git.enable = true;
      home-manager.enable = true;
      hyprland.enable = false;
      kde-apps = {
        enable = true;
        tablet = true;
        # 2560x1600 panel — 1.5x is the right Xwayland HiDPI scale (module default is 2 for 4K).
        xwaylandScale = 1.5;
        # Pin the llama-cpp start/stop toggle to the panel task manager.
        # Requires mine.llama-cpp.enable (which provides the script + polkit rule).
        llamaCppLauncher = true;
      };
      mako.enable = false;
      mpv.enable = true;
      nixvim = {
        enable = true;
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
            "${localLlm.activeModel.hfRepo}" = {
              name = "Qwen3.6 27B (goldenball)";
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
      obs-studio.enable = false;
      obsidian.enable = true;
      orca-slicer.enable = false;
      signal-desktop.enable = true;
      ssh.enable = true;
      teams-for-linux.enable = true;
      virt-viewer.enable = false;
      webcord.enable = true;
      zellij.enable = true;
    };

    alloy.enable = false;
    asusctl.enable = true;
    bluetooth.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    czkawka.enable = true;
    direnv.enable = true;
    ddc-i2c.enable = false;
    docker.enable = false;
    fonts.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    hypr.enable = false;
    iperf.enable = true;
    kde.enable = true;
    kde.tablet = true;

    # Local llama-server — Vulkan backend for Radeon 8060S (gfx1151).
    # ROCm HIP segfaults on gfx1151 Strix Halo (ollama #13589 / llama.cpp).
    # Vulkan via RADV is the stable GPU path on this generation.
    # Service is defined but NOT started at boot — start on demand:
    #   systemctl start llama-cpp   (loads model into GPU RAM, ~15s)
    #   systemctl stop llama-cpp    (frees GPU RAM for ComfyUI / gaming)
    # Active model: set localLlm.activeModel in hosts/goldenball/llm-config.nix
    # The SNI tray daemon (mine.home.kde-apps.llamaCppLauncher = true) registers
    # a system-tray icon alongside wifi/bluetooth/volume for one-click toggle.
    llama-cpp = {
      enable = true;
      vulkan = true;
      host = "0.0.0.0";
      port = 8080;
      hfRepo = localLlm.activeModel.hfRepo;
      hfFile = localLlm.activeModel.hfFile;
      contextSize = localLlm.activeModel.contextSize;
      cacheRamMiB = localLlm.activeModel.cacheRamMiB;
      extraFlags = localLlm.activeModel.extraFlags;
    };

    localization.enable = true;
    mullvad.enable = false;
    networkmanager.enable = true;
    nix.enable = true;
    nixos-r6t-baseline.enable = true;
    npm.enable = true;
    printing.enable = true;
    pinchflat.enable = false;
    prometheus-node-exporter.enable = false;
    rdfind.enable = false;
    sops.enable = true;
    sound.enable = true;
    ssh.enable = true;
    sshfs.enable = true;
    steam.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    usb4-sfp.enable = true;
    user.enable = true;
    v4l-utils.enable = true;
    zola.enable = true;
  };

  # ---------------------------------------------------------------------------
  # KWin compositor tuning — goldenball-specific (180 Hz eDP, VRR)
  # ---------------------------------------------------------------------------
  # These override / extend the shared kwinrc settings in modules/home/kde-apps.
  # Merged by home-manager's configFile mechanism (plasma-manager overrideConfig).
  home-manager.users.${userConfig.username} = {
    programs.plasma = {
      configFile = {
        # KWin compositor: target the panel's native 180 Hz and enable VRR.
        # MaxFPS / RefreshRate ensure KWin's render loop aims for the correct ceiling;
        # without these the compositor may auto-detect a lower rate after SDDM's
        # first-boot atomic commit failure.
        "kwinrc"."Compositing"."MaxFPS" = 180;
        "kwinrc"."Compositing"."RefreshRate" = 180;

        # VRR policy 2 = Always: allow the display to vary refresh rate freely
        # between 48–180 Hz (confirmed in panel EDID) during all rendering, not
        # just fullscreen. Eliminates frame-boundary tearing during window moves.
        # Requires amdgpu.freesync_video=1 (set in kernelParams above) to enable
        # FreeSync support in the amdgpu DRM driver for eDP connectors.
        "kwinrc"."Output eDP-1"."VrrPolicy" = 2;

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
