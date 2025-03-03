{ ... }: {

  imports = [
    home/awscli/default.nix
    home/fish/default.nix
    home/git/default.nix
    home/nixvim/default.nix
    home/python3/default.nix
    home/ssh/default.nix
    home/zellij/default.nix

    nixos/docker/default.nix
    nixos/localization/default.nix
    nixos/env/default.nix
    nixos/fzf/default.nix
    nixos/iperf/default.nix
    nixos/localization/default.nix
    nixos/prometheus-node-exporter/default.nix
    nixos/nix/default.nix
    nixos/nixpkgs/default.nix
    nixos/ssh/default.nix
    nixos/user/default.nix
    nixos/syncthing/default.nix
    nixos/tailscale/default.nix
  ];
}
