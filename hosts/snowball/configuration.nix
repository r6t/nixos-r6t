{ inputs, pkgs, lib, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # ASUS ROG Zephyrus G14 2025 (GA403W) Hardware Configuration
  # Hardware: AMD Ryzen AI 9 HX 370 (Zen 5), NVIDIA RTX 5070 Ti (8GB), MediaTek MT7925 WiFi 7

  # AMD iGPU support for hybrid graphics
  environment.variables.AMD_VULKAN_ICD = "RADV";

  # Kernel parameters for Ryzen AI 9 HX 370 + RTX 5070 Ti
  boot = {
    kernelParams = [
      # AMD iGPU optimizations for Radeon 890M (RDNA 3.5)
      # Conservative ppfeaturemask - no GFXOFF/STUTTER_MODE disable needed for iGPU
      "amdgpu.ppfeaturemask=0xffffffff"

      # CPU/Memory optimizations
      "amd_pstate=active" # AMD P-State EPP driver (active mode for best performance)
      "amd_iommu=on" # Enable IOMMU for better PCIe device isolation
      "iommu=pt" # Passthrough mode for performance

      # AI/NPU workload preparation (Ryzen AI NPU support is emerging)
      "amdgpu.gttsize=3072" # 3GB GTT for iGPU (light desktop use only)

      # WiFi 7 stability
      "pcie_aspm=off" # Disable PCIe ASPM for MediaTek WiFi 7 stability

      # Early KMS for smoother boot
      "amdgpu.dcdebugmask=0x10"

      # Hibernation resume target (will be set after hardware-configuration.nix)
      # "resume=UUID=<swap-uuid>"
    ];

    # Device used for resume from hibernation (set after hardware-configuration.nix)
    # resumeDevice = "/dev/disk/by-uuid/<swap-uuid>";

    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  # AMD iGPU hardware support
  hardware = {
    graphics = {
      extraPackages = with pkgs; [
        # AMD iGPU support for Radeon 890M
        rocmPackages.clr.icd
        rocmPackages.clr
      ];
    };

    firmware = with pkgs; [
      linux-firmware
    ];
  };

  # AMD P-State EPP for Ryzen AI 9 HX 370 power management
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  # Enable ROCm for AMD iGPU compute workloads
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

  services = {
    # Laptop input devices - touchpad support
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
        disableWhileTyping = true;
        accelProfile = "adaptive";
      };
    };

    # Fingerprint reader support (if present on this model)
    fprintd.enable = false;
  };

  networking = {
    enableIPv6 = false;
    hostName = "snowball";
    firewall = {
      enable = true;
      checkReversePath = false;
      # Standard ports for common services
      allowedTCPPorts = [ 22 8384 22000 ];
    };
  };

  system.stateVersion = "23.11";

  time.timeZone = "America/Los_Angeles";

  # modules
  mine = {
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
      mako.enable = false;
      mpv.enable = true;
      nixvim.enable = true;
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
    env.enable = true;
    fonts.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    hypr.enable = false;
    iperf.enable = true;
    kde.enable = true;
    localization.enable = true;
    mullvad.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    npm.enable = true;
    nvidia-cuda = {
      enable = true;
      package = "latest"; # RTX 5070 Ti (Blackwell) requires latest drivers (565+)
      openDriver = true; # Blackwell REQUIRES open kernel modules (proprietary doesn't support it)
      containerToolkit = false; # No container GPU passthrough needed
      installCudaToolkit = true; # Install CUDA for local ML/AI workloads
      powerManagement = true; # Enable for laptop suspend/hibernate support
      enableSettings = true; # Enable nvidia-settings GUI
      enableGspFirmware = true; # Required for RTX 50-series (Blackwell)
      prime = {
        enable = false; # Discrete-only mode (no hybrid graphics for now)
        # To enable hybrid graphics later, set enable = true and configure bus IDs:
        # offload = true;
        # amdgpuBusId = "PCI:65:0:0";  # AMD Radeon 890M iGPU (from lspci: 65:00.0)
        # nvidiaBusId = "PCI:64:0:0";  # NVIDIA RTX 5070 Ti dGPU (from lspci: 64:00.0)
      };
    };
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
