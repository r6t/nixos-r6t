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
    inputs.hardware.nixosModules.framework-13-7040-amd
    ./hardware-configuration.nix
    ../../modules/default.nix
  ];

  # system details
  boot.initrd.luks.devices."luks-9fc9c182-0bad-474f-a9bb-ee2e6aa1be50".device = "/dev/disk/by-uuid/9fc9c182-0bad-474f-a9bb-ee2e6aa1be50";
  networking.hostName = "mountainball";
  networking.firewall.allowedTCPPorts = [ 22 ];
  system.stateVersion = "23.11";

  # system modules
  mine.bluetooth.enable = true;
  mine.bolt.enable = true;
  mine.bootloader.enable = true;
  mine.docker.enable = true;
  mine.env.enable = true;
  mine.flatpak.enable = true;
  mine.fonts.enable = true;
  mine.fwupd.enable = true;
  mine.hypr.enable = true;
  mine.localization.enable = true;
  mine.mullvad.enable = true;
  mine.netdata.enable = true;
  mine.networkmanager.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.printing.enable = true;
  mine.sound.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.user.enable = true;
  mine.zsh.enable = true;

  # home modules
  mine.home.alacritty.enable = true;
  mine.home.apple-emoji.enable = true;
  mine.home.awscli.enable = true;
  mine.home.betaflight-configurator.enable = true;
  mine.home.bitwarden.enable = true;
  mine.home.brave.enable = true;
  mine.home.calibre.enable = true;
  mine.home.chromium.enable = true;
  mine.home.digikam.enable = true;
  mine.home.element-desktop.enable = true;
  mine.home.firefox.enable = true;
  mine.home.fontconfig.enable = true;
  mine.home.freecad.enable = true;
  mine.home.freerdp.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.hypridle.enable = true;
  mine.home.hyprland.enable = true;
  mine.home.hyprpaper.enable = true;
  mine.home.hyprpicker.enable = true;
  mine.home.kde-apps.enable = true;
  mine.home.librewolf.enable = true;
  mine.home.mako.enable = true;
  mine.home.neovim.enable = true;
  mine.home.obsidian.enable = true;
  mine.home.protonmail-bridge.enable = true;
  mine.home.python3.enable = true;
  mine.home.remmina.enable = true;
  mine.home.rofi.enable = true;
  mine.home.screenshots.enable = true;
  mine.home.signal-desktop.enable = true;
  mine.home.thunderbird.enable = true;
  mine.home.virt-manager.enable = true;
  mine.home.virt-viewer.enable = true;
  mine.home.vlc.enable = true;
  mine.home.vscodium.enable = true;
  mine.home.waybar.enable = true;
  mine.home.webcord.enable = true;
  mine.home.youtube-dl.enable = true;
  mine.home.zsh.enable = true;
}
