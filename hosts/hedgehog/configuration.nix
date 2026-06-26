{ inputs, pkgs, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.comfyui-nix.nixosModules.default
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # ---------------------------------------------------------------------------
  # Hedgehog — AMD 5900X / RTX 4070 Ti / 12GB VRAM
  # Role: Headless gaming server (Steam Remote Play streaming host) +
  #       ComfyUI image generation server
  #
  # Boot flow: systemd starts Xvfb (virtual display) → Steam (streaming host)
  #             ComfyUI (CUDA, auto-start)
  # Access: SSH, Steam Link clients on tailnet
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
  # Virtual display — Xvfb for Steam streaming (no physical monitor)
  # ---------------------------------------------------------------------------

  services.xserver = {
    enable = true;
    videoDrivers = [ "nvidia" ];
  };

  # Xvfb virtual framebuffer for headless Steam streaming.
  # Steam Remote Play needs an X11 display surface to capture.
  systemd.services.xvfb = {
    description = "Xvfb virtual framebuffer for Steam streaming";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.xvfb}/bin/Xvfb :1 -screen 0 3840x2160x24 -ac +extension GLX +extension RANDR +extension RENDER";
      Restart = "on-failure";
      RestartSec = "5";
      User = "root";
    };
  };

  # ---------------------------------------------------------------------------
  # Steam streaming host — runs in background with virtual display
  # ---------------------------------------------------------------------------

  # Ensure Steam runs with the virtual display
  environment.variables = {
    DISPLAY = ":1";
  };

  # ---------------------------------------------------------------------------
  # Modules
  # ---------------------------------------------------------------------------

  mine = {
    bluetooth.enable = false;
    direnv.enable = true;
    fwupd.enable = true;
    fzf.enable = true;
    iperf.enable = true;
    localization.enable = true;
    networkmanager.enable = true;
    nix.enable = true;
    nixos-r6t-baseline.enable = true;
    rdfind.enable = false;

    # RTX 4070 Ti — open NVIDIA kernel module (CUDA/NVENC identical between open/proprietary)
    nvidia-cuda = {
      enable = true;
      open = true;
      package = "latest";
      containerToolkit = false;
      installCudaToolkit = true;
    };

    # CLI home modules — headless server accessed via SSH
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
    steam.enable = true;
    tailscale.enable = true;
    user.enable = true;

  };

  # ComfyUI image generation — CUDA, accessible on tailnet.
  services.comfyui = {
    enable = true;
    gpuSupport = "cuda";
    port = 8188;
    listenAddress = "0.0.0.0";
  };
}
