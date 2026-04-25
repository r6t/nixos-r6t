{ lib, config, pkgs, ... }:

let
  commonPackages = import ../../lib/common-packages.nix pkgs;
in
{

  options = {
    mine.nixos-r6t-baseline.enable =
      lib.mkEnableOption "enable NixOS baseline system configuration";
  };

  config = lib.mkIf config.mine.nixos-r6t-baseline.enable {
    # TODO: migrate to dbus-broker. Pinning classic dbus-daemon because the
    # nixpkgs default flipped to dbus-broker in 26.05. Remove this line and use
    # `nixos-rebuild boot` + reboot on each host (the switch inhibitor blocks
    # live-switching dbus implementations).
    # - Option:        https://nixos.org/manual/nixos/stable/options#opt-services.dbus.implementation
    # - Nixpkgs PR:    https://github.com/NixOS/nixpkgs/pull/512050
    # - dbus-broker:   https://github.com/bus1/dbus-broker/wiki
    services.dbus.implementation = "dbus";

    # SSH brute-force protection
    services.fail2ban = {
      enable = true;
      maxretry = 5;
      bantime = "1h";
    };

    # Enable fish shell system-wide
    programs.fish.enable = true;

    # Add fish to /etc/shells
    environment.shells = with pkgs; [ fish ];

    # System packages — common set plus host-specific extras
    environment.systemPackages = commonPackages ++ (with pkgs; [
      bat
      cryptsetup
      ffmpeg
      home-manager
      inetutils
      python314
      sops
      tmux
      wireguard-tools
    ]);
  };
}
