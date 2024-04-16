{ pkgs, lib, ...}: {

    imports = [
      home/alacritty/default.nix
      home/apple-emoji/default.nix
      home/awscli/default.nix
      home/betaflight-configurator/default.nix
      home/bitwarden/default.nix
      home/brave/default.nix
      home/calibre/default.nix
      home/chromium/default.nix
      home/digikam/default.nix
      home/element-desktop/default.nix
      home/firefox/default.nix
      home/fontconfig/default.nix
      home/freecad/default.nix
      home/freerdp/default.nix
      home/git/default.nix
      home/home-manager/default.nix
      home/hypridle/default.nix
      home/hyprland/default.nix
      home/hyprlock/default.nix
      home/hyprpaper/default.nix
      home/hyprpicker/default.nix
      home/kde-apps/default.nix
      home/librewolf/default.nix
      home/mako/default.nix
      home/neovim/default.nix
      home/obsidian/default.nix
      home/protonmail-bridge/default.nix
      home/python3/default.nix
      home/remmina/default.nix
      home/rofi/default.nix
      home/screenshots/default.nix
      home/signal-desktop/default.nix
      home/ssh/default.nix
      home/thunderbird/default.nix
      home/virt-manager/default.nix
      home/virt-viewer/default.nix
      home/vlc/default.nix
      home/vscodium/default.nix
      home/waybar/default.nix
      home/webcord/default.nix
      home/youtube-dl/default.nix
      home/zsh/default.nix

      nixos/bluetooth/default.nix
      nixos/bolt/default.nix
      nixos/bootloader/default.nix
      nixos/docker/default.nix
      nixos/env/default.nix
      nixos/flatpak/default.nix
      nixos/fonts/default.nix
      nixos/fwupd/default.nix
      nixos/hypr/default.nix
      nixos/jovian/default.nix
      nixos/localization/default.nix
      nixos/mullvad/default.nix
      nixos/netdata/default.nix
      nixos/networkmanager/default.nix
      nixos/nix/default.nix
      nixos/nixpkgs/default.nix
      nixos/nvidia/default.nix
      nixos/ollama/default.nix
      nixos/printing/default.nix
      nixos/selfhost/default.nix
      nixos/sound/default.nix
      nixos/ssh/default.nix
      nixos/steam/default.nix
      nixos/syncthing/default.nix
      nixos/tailscale/default.nix
      nixos/thunderbay/default.nix
      nixos/user/default.nix
      nixos/zsh/default.nix
    ];
}