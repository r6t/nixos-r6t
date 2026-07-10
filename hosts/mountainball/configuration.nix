{ inputs, userConfig, ... }:

{
  imports = [
    inputs.hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
    ../../modules/home/makemkv/options.nix
    ../../modules/home/makemkv/config.nix
    ../../modules/home/obs-studio/options.nix
    ../../modules/home/obs-studio/config.nix
    ../../modules/home/orca-slicer/options.nix
    ../../modules/home/orca-slicer/config.nix
    ../../modules/home/virt-viewer/options.nix
    ../../modules/home/virt-viewer/config.nix
    ../../modules/nixos/ddc-i2c/options.nix
    ../../modules/nixos/ddc-i2c/config.nix
    ../../modules/nixos/docker/options.nix
    ../../modules/nixos/docker/config.nix
    ../../modules/nixos/mullvad/options.nix
    ../../modules/nixos/mullvad/config.nix
    ../../modules/nixos/pinchflat/options.nix
    ../../modules/nixos/pinchflat/config.nix
    ../../modules/nixos/rdfind/options.nix
    ../../modules/nixos/rdfind/config.nix
  ];

  boot = {
    resumeDevice = "/dev/mapper/luks-swap";
    kernelParams = [
      "resume=UUID=dea57a9c-895b-407d-b45f-f4cea665864f"
    ];
  };

  networking = {
    hostName = "mountainball";
    firewall = {
      enable = true;
      checkReversePath = false;
    };
  };

  systemd = {
    services = {
      nix-daemon.serviceConfig = {
        # Bound RAM use so long builds don't impact general desktop responsiveness.
        MemoryMax = "80%";
        MemoryHigh = "70%";
      };
    };
  };

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

  # Mountainball is iGPU-only (Radeon 780M / gfx1103, RDNA 3). It used to host an
  # R9700 eGPU via Thunderbolt and ran local LLM inference docked at a desk; the
  # R9700 has since moved to crown for headless inference. The previous eGPU
  # specialisation (PCIe hotplug params, KWIN_DRM_DEVICES, llama-cpp +
  # llama-cpp-steam-inhibit, Navi 10 switch-port udev rule) was deleted with that
  # hardware change. See git history if reviving an eGPU here ever comes up.

  # modules
  mine = {
    home = {
      git.signingPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINFSoABOk+KRUGtbxpS5PjcIHy4cYh7GOWxC7rNzv3Ua r6t@mountainball";
      nixvim = {
        enableSopsSecrets = true;
        # HA MCP is intentionally NOT enabled globally here.
        # It is only active when opencode is run from ~/git/appdaemons, via the
        # project-level opencode.json in that repo (not managed by this flake).

        # opencode -> remote TensorRT-LLM on crown via caddy + Route53.
        # Crown's TensorRT server defaults Qwen3 thinking off for direct
        # responses. The `thinking` variant opts in per request through
        # chat_template_kwargs.
        opencode-llamacpp = {
          enable = true;
          baseURL = "https://llm.r6t.io/v1";
          models = {
            # Model id MUST match the alias TensorRT-LLM reports at /v1/models.
            # Verify with:
            #   curl -s https://llm.r6t.io/v1/models | jq '.data[].id'
            "nvidia/Qwen3-8B-FP8" = {
              name = "Qwen3 8B FP8 (crown TensorRT)";
              context = 8192;
              output = 1024;
              variants = {
                # Cycle variants in opencode with the variant_cycle keybind.
                thinking.chat_template_kwargs = { enable_thinking = true; };
              };
            };
          };
        };
      };
    };
  };
}
