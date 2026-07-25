{ inputs, lib, pkgs, ... }:

{
  imports = [
    inputs.hardware.nixosModules.framework-11th-gen-intel
    ./hardware-configuration.nix
  ];

  networking = {
    # Keep the flake host name distinct while making the machine's local hostname generic.
    hostName = "localhost";
    firewall = {
      enable = true;
      checkReversePath = false;
      trustedInterfaces = lib.mkForce [ ];
      interfaces.tailscale0.allowedTCPPorts = [ 3389 ];
    };
  };

  mine.tailscale = {
    enable = true;
    extraUpFlags = [ "--hostname=marblecanyon" ];
  };

  environment.systemPackages = [ pkgs.kdePackages.krdp ];
  systemd.packages = [ pkgs.kdePackages.krdp ];

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    loader.systemd-boot.configurationLimit = lib.mkForce 3;
  };

  systemd.services.nix-daemon.serviceConfig = {
    # Bound RAM use so long builds don't impact general desktop responsiveness.
    MemoryMax = "80%";
    MemoryHigh = "70%";
  };

  system.stateVersion = "25.05";
}
