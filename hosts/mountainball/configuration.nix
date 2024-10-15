{
  inputs,
  ...
}:

 {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    inputs.hardware.nixosModules.framework-13-7040-amd
    inputs.sops-nix.nixosModules.sops
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
  mine.fzf.enable = true;
  mine.kde.enable = true;
  mine.localization.enable = true;
  mine.mullvad.enable = true;
  mine.netdata.enable = true;
  mine.networkmanager.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.printing.enable = true;
  mine.sops.enable = true;
  mine.sound.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.user.enable = true;

  # home modules
  mine.home.alacritty.enable = true;
  mine.home.atuin.enable = true;
  mine.home.awscli.enable = true;
  mine.home.betaflight-configurator.enable = true;
  mine.home.bitwarden.enable = true;
  mine.home.browsers.enable = true;
  mine.home.calibre.enable = true;
  mine.home.darktable.enable = true;
  mine.home.fish.enable = true;
  mine.home.fontconfig.enable = true;
  mine.home.freecad.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.kde-apps.enable = true;
  mine.home.mpv.enable = true;
  mine.home.nixvim.enable = true;
  mine.home.obsidian.enable = true;
  mine.home.obs-studio.enable = true;
  mine.home.protonmail-bridge.enable = true;
  mine.home.python3.enable = true;
  mine.home.signal-desktop.enable = true;
  mine.home.ssh.enable = true;
  mine.home.super-productivity.enable = true;
  mine.home.thunderbird.enable = true;
  mine.home.virt-viewer.enable = true;
  mine.home.vscodium.enable = true;
  mine.home.webcord.enable = true;
  mine.home.yt-dlp.enable = true;
  mine.home.zellij.enable = true;
}
