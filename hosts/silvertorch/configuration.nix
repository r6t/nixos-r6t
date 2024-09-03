{
  inputs,
  lib,
  config,
  pkgs,
  outputs,
  ...
}:

 {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    # <sops-nix>/modules/sops
    inputs.sops-nix.nixosModules.sops
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # system details
  boot.initrd.luks.devices."luks-ca693f0d-4d0a-4eee-ba6a-fdc2db22dfb1".device = "/dev/disk/by-uuid/ca693f0d-4d0a-4eee-ba6a-fdc2db22dfb1";
  networking.hostName = "silvertorch";
  networking.firewall.allowedTCPPorts = [ 22 3000 8080 11434 ];
  system.stateVersion = "23.11";

  # system modules
  mine.bootloader.enable = true;
  mine.docker.enable = true;
  mine.env.enable = true;
  mine.flatpak.enable = true;
  mine.fonts.enable = true;
  mine.fwupd.enable = true;
  mine.fzf.enable = true;
  mine.hypr.enable = false;
  mine.kde.enable = true;
  mine.libvirtd.enable = true;
  mine.localization.enable = true;
  mine.mullvad.enable = false;
  mine.netdata.enable = true;
  mine.networkmanager.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.nvidia.enable = true;
  mine.ollama.enable = true;
  mine.printing.enable = true;
  mine.sops.enable = true;
  mine.sound.enable = true;
  mine.ssh.enable = true;
  mine.steam.enable = false; # switched to flatpak
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.user.enable = true;
  mine.zsh.enable = true;

  # home modules
  mine.home.alacritty.enable = true;
  mine.home.apple-emoji.enable = false;
  mine.home.awscli.enable = true;
  mine.home.betaflight-configurator.enable = false;
  mine.home.bitwarden.enable = true;
  mine.home.brave.enable = true;
  mine.home.calibre.enable = false;
  mine.home.chromium.enable = true;
  mine.home.darktable.enable = false;
  mine.home.digikam.enable = false;
  mine.home.element-desktop.enable = false;
  mine.home.firefox.enable = true;
  mine.home.fontconfig.enable = true;
  mine.home.freecad.enable = false;
  mine.home.freerdp.enable = false;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.hypridle.enable = false;
  mine.home.hyprland.enable = false;
  mine.home.hyprpaper.enable = false;
  mine.home.hyprpicker.enable = false;
  mine.home.kde-apps.enable = true;
  mine.home.librewolf.enable = true;
  mine.home.mako.enable = false;
  mine.home.neovim.enable = true;
  mine.home.obsidian.enable = true;
  mine.home.protonmail-bridge.enable = true;
  mine.home.python3.enable = true;
  mine.home.remmina.enable = true;
  mine.home.rofi.enable = false;
  mine.home.screenshots.enable = false;
  mine.home.signal-desktop.enable = false;
  mine.home.ssh.enable = true;
  mine.home.thunderbird.enable = false;
  mine.home.libvirtd.enable = true;
  mine.home.virt-viewer.enable = true;
  mine.home.vlc.enable = true;
  mine.home.vscodium.enable = true;
  mine.home.waybar.enable = false;
  mine.home.webcord.enable = false;
  mine.home.yt-dlp.enable = false;
  mine.home.zsh.enable = true;
}
