{ inputs, userConfig, pkgs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.hardware.nixosModules.framework-13-7040-amd
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  networking = {
    hostName = "mountainball";
    firewall = {
      enable = true;
      checkReversePath = false;
      allowedTCPPorts = [ 22 ];
    };
  };


  systemd = {
    services = {
      nix-daemon.serviceConfig = {
        # Limit CPU usage to 50% for 16 vCPU
        # long builds (nvidia lxcs) impacted general service availability
        CPUQuota = "800%";
        MemoryMax = "80%";
        MemoryHigh = "70%";
      };
    };
  };

  services.fprintd.enable = false;

  # Touchpad: PIXA3854:00 093A:0274 (Framework 13 AMD built-in trackpad)
  home-manager.users.${userConfig.username} = {
    programs.plasma.input.touchpads = [
      {
        name = "PIXA3854:00 093A:0274 Touchpad";
        vendorId = "093a";
        productId = "0274";
        naturalScroll = true;
      }
    ];

    programs.fish.interactiveShellInit = ''
      # Load Qobuz credentials if available
      if test -r /run/secrets/qobuz/user
        set -gx QOBUZ_USER (string trim (cat /run/secrets/qobuz/user))
      end
      if test -r /run/secrets/qobuz/password
        set -gx QOBUZ_PASSWORD (string trim (cat /run/secrets/qobuz/password))
      end
    '';
  };

  # set secrets
  sops.secrets = {
    "qobuz/user" = {
      owner = userConfig.username;
    };
    "qobuz/password" = {
      owner = userConfig.username;
    };
  };

  system.stateVersion = "23.11";

  time.timeZone = "America/Los_Angeles";

  # Force amdgpu PCIe Gen 3 speed. Applied in base config because it is harmless when
  # no eGPU is present (option only takes effect if amdgpu initializes a second device).
  # AMD USB4 controllers may otherwise fall back to PCIe Gen 1 on the eGPU link.
  boot.extraModprobeConfig = ''
    options amdgpu pcie_gen_cap=0x40000
  '';

  # PCIe hotplug kernel parameters for Thunderbolt eGPU.
  # Applied in base config — harmless when undocked, required when docked.
  # pcie_ports=native: Linux owns native PCIe hotplug control instead of firmware.
  # hpmmiosize/hpmmioprefsize: large MMIO windows so ReBAR can be negotiated over TB.
  boot.kernelParams = [
    "pcie_ports=native"
    "pci=hpmmiosize=128M,hpmmioprefsize=16G"
  ];

  # eGPU docked mode — select "egpu" specialisation from the boot menu when at the desk.
  # Default boot (no specialisation) is AMD iGPU-only undocked laptop mode.
  # See docs/GAMING.md for full rationale and workflow.
  #
  # Hardware: Radeon AI Pro R9700 32GB in TH3P4G3 V3 enclosure via Thunderbolt 4.
  # Both host iGPU (Radeon 780M) and eGPU (R9700) use amdgpu — no driver complexity.
  #
  # TODO: After first docked boot, check whether KWin auto-selects R9700 without
  # KWIN_DRM_DEVICES (AMD+AMD may work without it). If so, dissolve this specialisation
  # entirely and move mine.ollama into base config.
  specialisation.egpu.configuration = {
    system.nixos.tags = [ "egpu" ];

    # AMD+AMD dual-GPU: both iGPU and eGPU use amdgpu, KWin manages them uniformly.
    # card0 = R9700 eGPU (desk monitor), card1 = Radeon 780M iGPU (laptop display).
    # When undocked, card0 does not exist and KWin skips it, using card1 (780M) only.
    # Verify card numbers after first docked boot:
    #   ls -la /dev/dri/by-path/ — confirm which PCI address is card0 vs card1
    #   qdbus org.kde.KWin /KWin supportInformation | grep "OpenGL renderer"
    environment.sessionVariables = {
      KWIN_DRM_DEVICES = "/dev/dri/card0:/dev/dri/card1";
    };

    # llama-server for local LLM inference on the R9700 32GB.
    # Kept in specialisation so llama-server does not start without the eGPU.
    #
    # Model: Qwen3.6-27B Q8_0 — the most Claude-like local option per harness-bench.
    # 15/16 with opencode at Q8. ~27GB VRAM — fits on 32GB with headroom.
    # Q8 over Q4: better on hard long-chain reasoning tasks (the ones that matter).
    # 32GB is the right card for this — a 24GB card forces Q4 or a smaller model.
    # Supports /think per-prompt extended thinking (Qwen3 native feature).
    # --jinja: required for correct Qwen3 tool-use prompt formatting.
    # To switch models: change hfRepo/hfFile and rebuild.
    mine.llama-cpp = {
      enable = true;
      host = "127.0.0.1";
      hfRepo = "unsloth/Qwen3.6-27B-GGUF";
      hfFile = "Qwen3.6-27B-Q8_0.gguf";
      contextSize = 131072;
      extraFlags = [ "--jinja" ];

      # Use the ROCm/HIP backend (pkgs.llama-cpp-rocm) for R9700 GPU acceleration.
      # Without this, the default nixpkgs llama-cpp package is CPU-only.
      rocm = true;

      # Restrict ROCm to the R9700 eGPU. On mountainball with two amdgpu devices,
      # ROCm device index 0 = R9700 (eGPU, higher performance), index 1 = 780M iGPU.
      # Verify with: rocminfo | grep -A5 "Agent [0-9]" after first docked boot.
      # If inference lands on the wrong GPU, swap to "1".
      rocmVisibleDevices = "0";
    };

    # Wire opencode to the local llama-server. Written directly via home.file
    # rather than through mine.home.nixvim.opencode-llamacpp because specialisation
    # configs cannot access custom mine.* options from home-manager modules.
    # opencode schema requires both context and output when limit is present.
    home-manager.users.${userConfig.username}.home.file.".config/opencode/opencode.json".text =
      builtins.toJSON {
        "$schema" = "https://opencode.ai/config.json";
        provider = {
          llamacpp = {
            npm = "@ai-sdk/openai-compatible";
            name = "llama.cpp (local)";
            options.baseURL = "http://127.0.0.1:8080/v1";
            models = {
              # Key must match the model alias as reported by llama-server /v1/models.
              # Supports /think for extended reasoning (type in opencode prompt).
              "Qwen3.6-27B-Q8_0" = {
                name = "Qwen3.6-27B Q8 (local R9700)";
                limit = {
                  context = 131072;
                  output = 32768;
                };
              };
            };
          };
        };
      };

    # Stop llama-cpp while Steam is running to free R9700 VRAM for games.
    # Polls every 3s for the steam process; stops llama-cpp.service when found,
    # restarts it when steam exits. Works for both terminal and GUI launcher launches.
    # This is a system-level service (not user-level) so it can manage llama-cpp.service.
    systemd.services.llama-cpp-steam-inhibit = {
      description = "Stop llama-cpp while Steam is running";
      after = [ "llama-cpp.service" ];
      wantedBy = [ "multi-user.target" ];
      path = [ pkgs.procps pkgs.systemd ];
      serviceConfig = {
        Type = "simple";
        Restart = "always";
        RestartSec = "5s";
        User = "root";
        ExecStart = pkgs.writeShellScript "llama-cpp-steam-inhibit" ''
          while true; do
            if pgrep -x steam > /dev/null 2>&1; then
              if systemctl is-active --quiet llama-cpp.service; then
                echo "Steam detected — stopping llama-cpp.service"
                systemctl stop llama-cpp.service
              fi
              # Wait for steam to fully exit
              while pgrep -x steam > /dev/null 2>&1; do
                sleep 3
              done
              echo "Steam exited — restarting llama-cpp.service"
              systemctl start llama-cpp.service
            fi
            sleep 3
          done
        '';
      };
    };
  };

  # modules
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
      freecad.enable = false; # 20260118 builds failing on pagmo
      git.enable = true;
      git.signingPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINFSoABOk+KRUGtbxpS5PjcIHy4cYh7GOWxC7rNzv3Ua r6t@mountainball";
      home-manager.enable = true;
      hyprland.enable = false;
      gnome-apps.enable = false;
      kde-apps.enable = true;
      makemkv.enable = true;
      mako.enable = false;
      mpv.enable = true;
      nixvim = {
        enable = true;
        enableSopsSecrets = true;
        # HA MCP is intentionally NOT enabled globally here.
        # It is only active when opencode is run from ~/git/appdaemons, via the
        # project-level opencode.json in that repo (not managed by this flake).
        # opencode-llamacpp is in the egpu specialisation — server only runs there.
      };
      obs-studio.enable = true;
      obsidian.enable = true;
      orca-slicer.enable = true;
      signal-desktop.enable = true;
      ssh.enable = true;
      teams-for-linux.enable = true;
      virt-viewer.enable = true;
      webcord.enable = true;
      zellij.enable = true;
    };

    alloy.enable = true;
    bluetooth.enable = true;
    bolt.enable = true;
    bootloader.enable = true;
    czkawka.enable = true;
    direnv.enable = true;
    ddc-i2c.enable = true;
    docker.enable = true;
    nixos-r6t-baseline.enable = true;
    fonts.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    hypr.enable = false;
    iperf.enable = true;
    gnome.enable = false;
    kde.enable = true;
    localization.enable = true;
    mullvad.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    npm.enable = true;
    printing.enable = true;
    pinchflat.enable = true;
    prometheus-node-exporter.enable = true;
    rdfind.enable = true;
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
