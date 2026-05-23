{ inputs, userConfig, ... }:
let
  # Pull activeModel from the shared config so the opencode context window
  # always matches what llama-server on goldenball is actually configured to use.
  goldenballLlm = import ../goldenball/llm-config.nix;
in
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
        # Limit CPU usage to 50% for 16 vCPU and bound RAM use, so long
        # builds don't impact general desktop responsiveness.
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

  # Mountainball is iGPU-only (Radeon 780M / gfx1103, RDNA 3). It used to host an
  # R9700 eGPU via Thunderbolt and ran local LLM inference docked at a desk; the
  # R9700 has since moved to crown for headless inference. The previous eGPU
  # specialisation (PCIe hotplug params, KWIN_DRM_DEVICES, llama-cpp +
  # llama-cpp-steam-inhibit, Navi 10 switch-port udev rule) was deleted with that
  # hardware change. See git history if reviving an eGPU here ever comes up.

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

        # opencode -> remote llama-server on goldenball via crown's caddy + Route53.
        # Goldenball runs Qwen3.6-27B-Q6_K with `--reasoning off` as the
        # global default (fast chat). The `thinking` variant
        # below re-enables thinking on a per-request basis through the chat
        # template kwarg — opencode merges variant attrs into the request body,
        # llama-server reads chat_template_kwargs from the body and applies
        # them to the jinja template.
        opencode-llamacpp = {
          enable = true;
          baseURL = "https://llm.r6t.io/v1";
          models = {
            # Model id MUST match the alias llama-server reports at /v1/models.
            # Currently that's the full HF repo string. Verify with:
            #   curl -s https://llm.r6t.io/v1/models | jq '.data[].id'
            "unsloth/Qwen3.6-27B-GGUF" = {
              name = "Qwen3.6 27B (goldenball)";
              context = goldenballLlm.activeModel.contextSize;
              output = 32768;
              variants = {
                # default variant gets no extras — server's --reasoning off
                # applies, fast direct responses.
                # `thinking` flips Qwen3.6 reasoning on for this request only.
                # Cycle variants in opencode with the variant_cycle keybind.
                thinking.chat_template_kwargs = { enable_thinking = true; };
              };
            };
          };
        };
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
