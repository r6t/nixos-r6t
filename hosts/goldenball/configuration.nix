{ inputs, pkgs, lib, userConfig, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # Lenovo Legion Go (1st gen, 83E1) Hardware Configuration
  # Hardware: AMD Ryzen Z1 Extreme (Phoenix), AMD Radeon 780M (RDNA 3, gfx1103),
  #           16GB LPDDR5x, 8.8" 2560x1600 (portrait-native) 144Hz touchscreen,
  #           built-in gamepads (detachable), USB4, Wi-Fi 6E
  environment.variables.AMD_VULKAN_ICD = "RADV";

  boot = {
    kernelParams = [
      # AMD GPU: keep all power features enabled — the 780M iGPU doesn't have
      # the external display timing issues that Strix Halo had
      "amdgpu.ppfeaturemask=0xffffffff"

      "amd_pstate=guided" # AMD P-State driver (guided mode for efficiency)

      # Hibernation resume target (encrypted swap)
      "resume=UUID=2816b186-2633-4e3c-996c-f6ea67bb8147"
    ];

    # Device used for resume from hibernation
    resumeDevice = "/dev/disk/by-uuid/2816b186-2633-4e3c-996c-f6ea67bb8147";

    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
  };

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.firmware = with pkgs; [
    linux-firmware
  ];

  # AMD P-State EPP for better power management
  powerManagement.cpuFreqGovernor = lib.mkDefault "schedutil";

  # Handheld Daemon (HHD): maps the Legion Go's built-in gamepad controllers
  # (which appear as separate input devices) into a unified virtual gamepad.
  # Also provides TDP control via adjustor and the acpi_call module.
  # USB4 dock stability: disable D3cold on the Intel PCIe switches inside the
  # Plugable USB4-HUB3A (8086:0b26, 8086:15ef) — hotplugged devices can fail
  # to wake from deep power-off states.
  # Touchscreen support
  services = {
    handheld-daemon = {
      enable = true;
      user = userConfig.username;
      ui.enable = true;
      adjustor.enable = true;
    };
    udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x0b26", ATTR{d3cold_allowed}="0"
      ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x8086", ATTR{device}=="0x15ef", ATTR{d3cold_allowed}="0"
    '';
    libinput = {
      enable = true;
      touchpad = {
        naturalScrolling = true;
        tapping = true;
      };
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

  # Legion Go supports S3 deep sleep (unlike the Z13 which was s2idle-only).
  # On battery: suspend-then-hibernate for safety (sleep 30min then hibernate
  # to encrypted swap, preserving game state).
  # On AC: plain suspend so the system wakes quickly.
  # NOTE: GNOME power settings (modules/home/gnome-apps dconf) also control
  # sleep behavior in-session. These logind settings serve as fallback
  # (pre-login, GNOME crash). Keep both in sync.
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "suspend";
    HandleLidSwitchDocked = "ignore";
    HandlePowerKey = "suspend"; # physical power button = quick suspend
  };

  # Defines HOW suspend-then-hibernate works (not WHEN it triggers).
  # Used by both logind and GNOME power settings when they invoke systemd-sleep.
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
  '';

  # YubiKey: OTP slots are locked by an old workplace access code, so HMAC-SHA1
  # challenge-response for LUKS boot unlock is not possible with this key.
  # FIDO2 credentials (Bitwarden, passkeys) work fine — separate application.
  # The yubikey-luks-enroll module remains available if a new key is obtained.

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
      gnome-apps.enable = true;
      gnome-apps.tablet = true;
      kde-apps.enable = false;
      kde-apps.tablet = false;
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
    asusctl.enable = false; # Lenovo, not ASUS
    bluetooth.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    czkawka.enable = true;
    direnv.enable = true;
    ddc-i2c.enable = false;
    docker.enable = false;
    nixos-r6t-baseline.enable = true;
    ollama.enable = false; # 16GB RAM — use mountainball/crown for LLM work
    open-webui.enable = false;
    fonts.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    hypr.enable = false;
    iperf.enable = true;
    gnome.enable = true;
    gnome.tablet = true;
    kde.enable = false;
    kde.tablet = false;
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
    yubikey-luks-enroll.enable = false;
    zola.enable = true;
  };
}
