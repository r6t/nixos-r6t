{ inputs, pkgs, lib, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # ASUS ROG Z13 2025 AI Max 395 (GZ302) Hardware Configuration
  # Hardware: AMD Ryzen AI MAX+ 395 (Strix Halo), AMD Radeon 8060S, MediaTek MT7925 WiFi
  environment.variables.AMD_VULKAN_ICD = "RADV";

  # Kernel parameters for Strix Halo optimization
  boot = {
    kernelParams = [
      # AMD GPU optimizations for Radeon 8060S (RDNA 3.5)
      # 0xfffd7fff disables GFXOFF (bit 15) and STUTTER_MODE (bit 17) to prevent microstuttering
      # on high refresh rate external displays while keeping other power features enabled
      "amdgpu.ppfeaturemask=0xfffd7fff"

      # IOMMU passthrough: zero translation overhead for GPU compute,
      # while keeping IOMMU active for USB4 PCIe tunneling and device isolation
      "iommu=pt"

      # GPU-accessible system RAM limit (not a reservation — shared with OS).
      # 112GB ceiling for large LLM inference; leaves 16GB for OS/KDE/browsers.
      # gpt-oss:120b (65GB weights + ~35GB KV @ 256K ctx ≈ 100GB) fits within budget.
      # qwen3-coder:30b (18GB + ~30GB KV @ 256K ≈ 48GB) has ample headroom.
      "ttm.pages_limit=29360128"

      "amd_pstate=guided" # AMD P-State driver (guided mode for efficiency)
      # Hibernation resume target (encrypted swap)
      "resume=UUID=2816b186-2633-4e3c-996c-f6ea67bb8147"

      "amdgpu.abmlevel=0" # Disable panel power savings (causes timing issues with external displays)
    ];

    # Device used for resume from hibernation
    resumeDevice = "/dev/disk/by-uuid/2816b186-2633-4e3c-996c-f6ea67bb8147";

    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      rocmPackages.clr.icd
      rocmPackages.clr
    ];
  };

  hardware.firmware = with pkgs; [
    linux-firmware
  ];

  # MediaTek MT7925 Wi-Fi: load driver at boot (not via udev) to survive
  # cold boots after failed s2idle resume, and disable ASPM for stability
  boot.kernelModules = [ "mt7925e" ];
  boot.extraModprobeConfig = "options mt7925e disable_aspm=1";

  # AMD P-State EPP for better power management
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  # Enable ROCm for AI/LLM workloads on AMD Radeon 8060S
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  # USB4/Thunderbolt display stability: the Strix Halo USB4 host routers
  # (1022:158d, 1022:158e) use DPIA (DisplayPort-over-USB4) adapters that are
  # unstable when the router enters runtime suspend. Certain DPIA link_index
  # assignments (observed: index 8) fail ~10 min after boot with flip_done
  # timeouts and full tunnel collapse. Keeping the routers out of runtime
  # suspend prevents the DPIA path from entering a broken state.
  # Also disable D3cold on the Intel PCIe switches inside the USB4 hub
  # (8086:0b26, 8086:15ef) since they are hotplugged and can fail to wake.
  services.udev.extraRules = ''
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158d", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x1022", ATTR{device}=="0x158e", ATTR{power/control}="on"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x0b26", ATTR{d3cold_allowed}="0"
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15ef", ATTR{d3cold_allowed}="0"
  '';

  # Touchpad and input device support for tablet
  services.libinput = {
    enable = true;
    touchpad = {
      naturalScrolling = true;
      tapping = true;
      disableWhileTyping = true;
    };
  };

  networking = {
    enableIPv6 = false;
    hostName = "goldenball";
    firewall = {
      enable = true;
      checkReversePath = false;
      # temp extras while moving services around
      allowedTCPPorts = [ 22 8384 8443 22000 ];
    };
  };

  services.fprintd.enable = false;

  # Strix Halo only supports S0 (s2idle) and S4 (hibernate), no S3 deep suspend.
  # s2idle is unreliable on battery (freezes requiring hard power-off).
  # On AC: stay in s2idle so the system remains available on the network.
  # On battery: suspend-then-hibernate for safety.
  # NOTE: KDE PowerDevil (modules/home/kde-apps) blocks logind lid-switch handling
  # and enforces its own sleep policy via whenSleepingEnter. These logind settings
  # serve as fallback (pre-login, PowerDevil crash). Keep both in sync.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
  };

  # Defines HOW suspend-then-hibernate works (not WHEN it triggers).
  # Used by both logind and PowerDevil when they invoke systemd-sleep.
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=freeze
  '';

  system.stateVersion = "23.11";

  time.timeZone = "America/Los_Angeles";

  # modules
  mine = {
    # LUKS-encrypted SD card (mmcblk0p1), unlocked post-boot via keyfile
    mountLuksStore = {
      goldenstore = {
        device = "/dev/disk/by-uuid/16984564-063d-4e3c-93ca-f0e1f4d6de24";
        keyFile = "/root/mmcblk0.key";
        mountPoint = "/mnt/goldenstore";
      };
    };
    flatpak = {
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
      aider.enable = true;
      alacritty.enable = true;
      atuin.enable = true;
      bitwarden.enable = true;
      browsers.enable = true;
      darktable.enable = true;
      drawio.enable = true;
      fish.enable = true;
      fontconfig.enable = true;
      freecad.enable = false;
      git.enable = true;
      home-manager.enable = true;
      hyprland.enable = false;
      kde-apps.enable = true;
      kde-apps.tablet = true;
      mako.enable = false;
      mpv.enable = true;
      nixvim.enable = true;
      nixvim.opencode-ollama = {
        enable = true;
        # Limits tell OpenCode how to partition the Ollama context window.
        # OLLAMA_CONTEXT_LENGTH=262144, tuned for qwen3-coder as daily driver.
        models = {
          "qwen3-coder:30b" = {
            name = "Qwen3-Coder 30B MoE (local)";
            context = 229376; # 224K input — leaves 32K for code output
            output = 32768;
          };
          "gpt-oss:120b" = {
            name = "GPT-OSS 120B (local, MXFP4)";
            context = 49152; # 48K input — conservative for OpenCode; use Open-WebUI for higher ctx
            output = 16384;
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
    nixos-r6t-baseline.enable = true;
    ollama = {
      enable = true;
      # ROCm HIP backend segfaults on gfx1151 Strix Halo iGPUs (ollama #13589).
      # Vulkan works as a workaround until ollama gets native gfx1151 support.
      acceleration = "vulkan";
      models = [
        "gpt-oss:120b" # 65GB MXFP4 — flagship reasoning/agentic, 128K ctx, native tool calling
        "qwen3-coder:30b" # 19GB — 30B/3.3B-active MoE, 256K ctx, fast agentic coding
        # "qwen3-coder-next" # needs ollama >=0.16 (nixpkgs has 0.15.4)
      ];
      # 128GB unified RAM, 112GB GPU-accessible (TTM). Tuned for qwen3-coder:30b
      # as the primary model: 18GB weights + KV at 256K ≈ 48GB, well within budget.
      # gpt-oss:120b fits at 256K too (~100GB < 112GB TTM) but is used via Open-WebUI
      # where num_ctx can be tuned per-model in the UI.
      environmentVariables = {
        OLLAMA_CONTEXT_LENGTH = "262144";
      };
    };
    open-webui.enable = true;
    fonts.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    hypr.enable = false;
    iperf.enable = true;
    kde.enable = true;
    kde.tablet = true;
    localization.enable = true;
    mullvad.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
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
}
