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
  mine.env.enable = true;
  mine.flatpak.enable = true;
  mine.fonts.enable = true;
  mine.fwupd.enable = true;
  mine.fzf.enable = true;
  mine.kde.enable = true;
  mine.localization.enable = true;
  mine.netdata.enable = true;
  mine.networkmanager.enable = true;
  mine.nix.enable = true;
  mine.nixpkgs.enable = true;
  mine.nvidia.enable = true;
  mine.ollama.enable = true;
  mine.open-webui.enable = true;
  mine.sops.enable = true;
  mine.sound.enable = true;
  mine.ssh.enable = true;
  mine.syncthing.enable = true;
  mine.tailscale.enable = true;
  mine.user.enable = true;
  mine.zsh.enable = true;

  # home modules
  mine.home.alacritty.enable = true;
  mine.home.awscli.enable = true;
  mine.home.bitwarden.enable = true;
  mine.home.brave.enable = true;
  mine.home.firefox.enable = true;
  mine.home.fontconfig.enable = true;
  mine.home.git.enable = true;
  mine.home.home-manager.enable = true;
  mine.home.kde-apps.enable = true;
  mine.home.nixvim.enable = true;
  mine.home.python3.enable = true;
  mine.home.remmina.enable = true;
  mine.home.ssh.enable = true;
  mine.home.vlc.enable = true;
  mine.home.vscodium.enable = true;
  mine.home.yt-dlp.enable = true;
  mine.home.zsh.enable = true;
}
