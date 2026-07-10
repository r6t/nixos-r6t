{ lib, config, pkgs, ... }:

let
  commonPackages = import ../../lib/common-packages.nix pkgs;
in
{
  # Legacy compatibility module for hosts not migrated to modules.nixos.r6t-base
  # yet. New profile-based hosts should import r6t-base instead.
  imports = [ ./options.nix ];

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
