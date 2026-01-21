{ inputs, pkgs, ... }:
{
  imports = [
    ./r6-lxc-base.nix
    ./r6-lxc-mullvad-dns-add-on.nix
    inputs.home-manager.nixosModules.home-manager
    inputs.nix-flatpak.nixosModules.nix-flatpak
    inputs.sops-nix.nixosModules.sops
    ../modules/default.nix
  ];

  nixpkgs.config.allowUnfree = true;

  networking = {
    hostName = "remote-plasma";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        22 # SSH
        47984 # Sunshine HTTPS
        47989 # Sunshine HTTP
        47990 # Sunshine Web UI
        48010 # Sunshine RTSP
      ];
      allowedUDPPorts = [
        47998 # Sunshine video
        47999 # Sunshine control
        48000 # Sunshine audio
        48002 # Sunshine mic (input)
        48010 # Sunshine RTSP
      ];
    };
  };

  # AMD GPU (Radeon 780M iGPU) support for VAAPI encoding
  # Requires Incus GPU passthrough: /dev/dri/card0, /dev/dri/renderD128
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      libva # VAAPI
      libva-utils # vainfo
      mesa # OpenGL/Vulkan
      libva-vdpau-driver # VDPAU backend for VAAPI
      libvdpau-va-gl # VDPAU via VAAPI
    ];
  };

  # Video/render group for GPU access
  users.users.r6t.extraGroups = [ "video" "render" ];

  # DNS override for services
  services = {
    dnsmasq.settings.address = [
      "/grafana.r6t.io/192.168.6.1"
      "/r6t.io/192.168.6.10"
    ];

    # Sunshine for remote desktop streaming (Moonlight server)
    sunshine = {
      enable = true;
      autoStart = true;
      openFirewall = false; # Already opened above
      capSysAdmin = true; # Needed for KMS/Wayland capture
      settings = {
        sunshine_name = "remote-plasma";
        output_name = 0;
        # VAAPI encoder for AMD GPU hardware acceleration
        encoder = "vaapi";
        adapter_name = "/dev/dri/renderD128";
        audio_sink = ""; # Auto-detect PipeWire
      };
    };
  };

  mine = {
    user.enable = true;
    kde.enable = true;
    sound.enable = true;
    ssh.enable = true;

    home = {
      alacritty.enable = true;
      atuin.enable = true;
      browsers.enable = true;
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      kde-apps.enable = true;
      nixvim = {
        enable = true;
        enableSopsSecrets = false; # No sops keys in container
      };
      ssh.enable = true;
      zellij.enable = true;
    };
  };
}
