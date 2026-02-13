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

      # AI/LLM workload optimizations
      "amd_iommu=off" # Lower latency GPU memory access
      "amdgpu.gttsize=65536" # 64GB or 50% RAM to GPU

      "amd_pstate=guided" # AMD P-State driver (guided mode for efficiency)
      # Hibernation resume target (encrypted swap)
      "resume=UUID=ba7ca596-09b0-476b-9917-c11b5d98ea44"

      "pcie_aspm=off" # WiFi 7 stability
      "amdgpu.dcdebugmask=0x10" # Early KMS
      "amdgpu.abmlevel=0" # Disable panel power savings (causes timing issues with external displays)
    ];

    # Device used for resume from hibernation
    resumeDevice = "/dev/disk/by-uuid/ba7ca596-09b0-476b-9917-c11b5d98ea44";

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

  # AMD P-State EPP for better power management
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  # Enable ROCm for AI/LLM workloads on AMD Radeon 8060S
  systemd.tmpfiles.rules = [
    "L+    /opt/rocm/hip   -    -    -     -    ${pkgs.rocmPackages.clr}"
  ];

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
