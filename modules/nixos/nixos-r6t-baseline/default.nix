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
