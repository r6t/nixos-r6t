{ pkgs, lib, ...}: {

    imports = [
      apps/netdata/default.nix
      apps/ssh/default.nix
      apps/syncthing/default.nix
      apps/tailscale/default.nix
      apps/zsh/default.nix

      system/fwupd/default.nix
      system/localization/default.nix
      system/nix/default.nix
      system/nixpkgs/default.nix
    ];
}