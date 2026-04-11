{ inputs, userConfig, ... }:
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
  home-manager.users.${userConfig.username}.programs.plasma.input.touchpads = [
    {
      name = "PIXA3854:00 093A:0274 Touchpad";
      vendorId = "093a";
      productId = "0274";
      naturalScroll = true;
    }
  ];

  system.stateVersion = "23.11";

  time.timeZone = "America/Los_Angeles";

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
        enableHaMcp = true;
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
