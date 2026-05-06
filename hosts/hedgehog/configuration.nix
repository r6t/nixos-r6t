{ inputs, userConfig, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # ---------------------------------------------------------------------------
  # Hedgehog — AMD CPU / RTX 4070 Ti / 4K 165Hz TV
  # Role: HTPC gaming console (SteamOS-style gamescope session) +
  #       on-demand image generation (stable-diffusion.cpp, manual start)
  #
  # Boot flow: SDDM auto-login → gamescope session → Steam Big Picture
  # No KDE or other DE — gamescope is the only session.
  # sd-server starts manually (autoStart = false) when gaming is not active.
  # ---------------------------------------------------------------------------

  networking = {
    hostName = "hedgehog";
    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 ];
    };
  };

  system.stateVersion = "25.05";
  time.timeZone = "America/Los_Angeles";

  # ---------------------------------------------------------------------------
  # Gamescope session — SteamOS-style, no traditional DE
  # ---------------------------------------------------------------------------

  # SDDM with auto-login into the gamescope session.
  # services.displayManager.defaultSession must match the session name registered
  # by programs.steam.gamescopeSession (which creates "steam-gamescope").
  services = {
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
        autoNumlock = true;
      };
      autoLogin = {
        enable = true;
        user = userConfig.username;
      };
      # The gamescope session is registered as "steam" by nixpkgs steam.nix
      # (share/wayland-sessions/steam.desktop). Not "steam-gamescope".
      defaultSession = "steam";
    };

    # PipeWire — required for gamescope's -pipewire-dmabuf Steam arg
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
  };

  security.rtkit.enable = true;

  # Gamescope: capSysNice allows the compositor to set realtime scheduling priority.
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };

  # gamescopeSession registers "steam-gamescope" as a display manager session.
  # mine.steam (in the mine block below) sets programs.steam.enable = true plus
  # the bubblewrap sandbox, Proton-GE, MangoHud, and realtime scheduling limits.
  # This block adds the gamescope session configuration on top.
  programs.steam.gamescopeSession = {
    enable = true;
    # 4K 165Hz — match the TV's native resolution and max refresh rate.
    # --hdr-enabled: requires HDR-capable display and driver support.
    # --adaptive-sync: variable refresh rate (FreeSync/G-Sync compatible).
    # --rt: realtime scheduling for the gamescope compositor thread.
    args = [
      "--output-width"
      "3840"
      "--output-height"
      "2160"
      "--refresh"
      "165"
      "--fullscreen"
      "--hdr-enabled"
      "--adaptive-sync"
      "--rt"
    ];
  };

  # modules
  mine = {
    bluetooth.enable = true;
    bootloader.enable = true;
    direnv.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    localization.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixos-r6t-baseline.enable = true;
    rdfind.enable = true;

    # RTX 4070 Ti — NVIDIA open kernel module, no containerToolkit or CUDA dev tools
    nvidia-cuda = {
      enable = true;
      package = "latest";
      containerToolkit = false;
      installCudaToolkit = false;
    };

    # CLI home modules — hedgehog is primarily accessed via SSH
    home = {
      atuin.enable = true;
      fish.enable = true;
      git.enable = true;
      git.signingPubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINFSoABOk+KRUGtbxpS5PjcIHy4cYh7GOWxC7rNzv3Ua r6t@mountainball";
      home-manager.enable = true;
      nixvim = {
        enable = true;
        enableSopsSecrets = false;
        enableHaMcp = false;
      };
      ssh.enable = true;
      zellij.enable = true;
    };

    sound.enable = true;
    ssh.enable = true;
    user.enable = true;

    # Steam stack: programs.steam + bubblewrap sandbox + MangoHud + Proton-GE +
    # gamemode + realtime scheduling limits. gamescopeSession configured above.
    steam.enable = true;

    # Image generation — FLUX.1-schnell, manual start only.
    # autoStart = false: service is defined but does NOT start at boot.
    # To start: systemctl start stable-diffusion-cpp
    # To stop:  systemctl stop stable-diffusion-cpp
    # Pre-download model to /var/lib/stable-diffusion-cpp/models/ before first use:
    #   huggingface-cli download city96/FLUX.1-schnell-gguf \
    #     --include "flux1-schnell-Q8_0.gguf" \
    #     --local-dir /var/lib/stable-diffusion-cpp/models/
    stable-diffusion-cpp = {
      enable = true;
      host = "127.0.0.1";
      port = 1234;
      cuda = true;
      autoStart = false;
      modelFile = "/var/lib/stable-diffusion-cpp/models/flux1-schnell-Q8_0.gguf";
      extraFlags = [
        "--diffusion-fa" # flash attention: lower VRAM usage in diffusion transformer
        "--type"
        "q8_0"
      ];
    };
  };
}
