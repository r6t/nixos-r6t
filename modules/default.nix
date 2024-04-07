{ pkgs, lib, ...}: {

    imports = [
      home/git/default.nix
      home/neovim/default.nix
      nixos/bluetooth/default.nix
      nixos/bolt/default.nix
      nixos/docker/default.nix
      nixos/env/default.nix
      nixos/flatpak/default.nix
      nixos/fonts/default.nix
      nixos/fwupd/default.nix
      nixos/hypr/default.nix
      nixos/localization/default.nix
      nixos/mullvad/default.nix
      nixos/netdata/default.nix
      nixos/nix/default.nix
      nixos/nixpkgs/default.nix
      nixos/ollama/default.nix
      nixos/printing/default.nix
      nixos/sound/default.nix
      nixos/ssh/default.nix
      nixos/steam/default.nix
      nixos/syncthing/default.nix
      nixos/tailscale/default.nix
      nixos/zsh/default.nix
      nixos/user/default.nix
    ];
}