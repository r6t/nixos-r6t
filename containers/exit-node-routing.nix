{ config, pkgs, lib, userConfig, ... }:
{
  imports = [
    ./r6-tailnet-base.nix
    ../modules/nixos/exit-node-routing/default.nix
  ];

  networking = {
    hostName = "mullvad-seattle";
    firewall = {
      enable = true;
      trustedInterfaces = [ "tailscale0" ];
      allowedUDPPorts = [ 3748 41641 51820 ];
      checkReversePath = "loose";
    };
  };

  mine.exit-node-routing = {
    enable = true;
  };
  # Systemd dependencies
  systemd.services.jellyfin.after = [ "tailscale.service" ];
}

