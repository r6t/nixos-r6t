{ pkgs, lib, ...}: {

    imports = [
      nixos/docker/default.nix
      nixos/netdata/default.nix
      nixos/ollama/default.nix
      nixos/ssh/default.nix
      nixos/syncthing/default.nix
      nixos/tailscale/default.nix
      nixos/zsh/default.nix

      nixos/bolt/default.nix
      nixos/env/default.nix
      nixos/fwupd/default.nix
      nixos/localization/default.nix
      nixos/nix/default.nix
      nixos/nixpkgs/default.nix
    ];
}