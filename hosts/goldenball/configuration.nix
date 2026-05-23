{ inputs, pkgs, lib, ... }:
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
  # Role: primary workstation + local LLM (vulkan, on-demand)
  # ---------------------------------------------------------------------------

  environment.variables.AMD_VULKAN_ICD = "RADV";

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;

    kernelParams = [
      # Disable GFXOFF (bit 15) and STUTTER_MODE (bit 17) — prevents
      # microstuttering on high-refresh external displays while keeping all
      # other power features enabled.
      "amdgpu.ppfeaturemask=0xfffd7fff"

      # IOMMU passthrough: zero-cost translation for GPU compute while keeping
      # IOMMU active for USB4 PCIe tunneling and device isolation.
      "iommu=pt"

      # GPU-accessible system RAM limit (shared with OS, not reserved).
      # 96 GB ceiling for large LLM inference; leaves 32 GB for OS/KDE/browsers.
      # 25165824 = 96 GB / 4 KB page size.
      "ttm.pages_limit=25165824"

      "amd_pstate=guided"

      # Hibernation resume target (encrypted swap — update UUID after install)
      "resume=UUID=2816b186-2633-4e3c-996c-f6ea67bb8147"

      # Disable panel adaptive brightness (causes timing issues on external displays)
      "amdgpu.abmlevel=0"
    ];

    # Device used for resume from hibernation
    resumeDevice = "/dev/disk/by-uuid/2816b186-2633-4e3c-996c-f6ea67bb8147";
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

  # MediaTek MT7925 Wi-Fi: load driver at boot to survive cold boots after
  # failed s2idle resume; disable ASPM for stability.
  boot.kernelModules = [ "mt7925e" ];
  boot.extraModprobeConfig = "options mt7925e disable_aspm=1";

  # ROCm symlink for AI/LLM tooling
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

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

  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=freeze
  '';

  networking = {
    enableIPv6 = false;
    hostName = "goldenball";
    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 22 8384 8443 22000 ];
    };
  };

  system.stateVersion = "23.11";
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
      kde-apps.enable = true;
      kde-apps.tablet = true;
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
    mullvad.enable = true;
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
}
