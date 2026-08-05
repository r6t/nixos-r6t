{ inputs, lib, pkgs, ... }:

{
  imports = [
    inputs.hardware.nixosModules.framework-11th-gen-intel
    ./hardware-configuration.nix
  ];

  boot = {
    kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    loader.systemd-boot.configurationLimit = lib.mkForce 3;
  };

  networking = {
    # Keep the flake host name distinct while making the machine's local hostname generic.
    hostName = "workstation";
    firewall = {
      enable = true;
      checkReversePath = false;
      trustedInterfaces = lib.mkForce [ ];
      interfaces.tailscale0.allowedTCPPorts = [ 3389 ];
    };
  };

  environment.systemPackages = [ pkgs.kdePackages.krdp ];
  systemd.packages = [ pkgs.kdePackages.krdp ];

  systemd.services.nix-daemon.serviceConfig = {
    # Bound RAM use so long builds don't impact general desktop responsiveness.
    MemoryMax = "80%";
    MemoryHigh = "70%";
  };

  system.stateVersion = "25.05";

  mine = {
    networkmanager.wifiMacAddress = "random";

    tailscale = {
      enable = true;
      extraUpFlags = [ "--hostname=marblecanyon" ];
    };

    user = {
      extraGroups = [ "input" "networkmanager" "wheel" ];
      authorizedKeysFromGithub = true;
      authorizeRootKeys = false;
    };

    home = {
      browsers.firefoxSync.enable = false;

      kde-apps.taskLaunchers = [
        "applications:org.kde.krusader.desktop"
        "applications:Alacritty.desktop"
        "applications:firefox.desktop"
      ];
    };
  };
}
