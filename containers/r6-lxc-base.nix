{ config, pkgs, lib, modulesPath, ... }:
{
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
    ../modules/nixos/localization/default.nix
  ];

  boot.isContainer = true;
  system.stateVersion = "23.11";

  environment.systemPackages = with pkgs; [
    cloud-init
    curl
    dig
    fd
    git
    git-remote-codecommit
    gnumake
    lshw
    neovim
    netcat
    nmap
    openssl
    pciutils
    ripgrep
    tree
    unzip
    usbutils
    wget
    zip
  ];

  mine.localization.enable = true;

  # 1. Enable systemd-networkd to receive network info from cloud-init.
  systemd.network.enable = true;
  networking.useNetworkd = true;

  # 2. Enable systemd-resolved. We do NOT need any extraConfig.
  # NixOS defaults will correctly set up the stub resolver on 127.0.0.53
  # and create the appropriate /etc/resolv.conf symlink.
  services.resolved.enable = true;

  # bolt this back down after lxcs are stable
  networking.firewall.enable = false;

  # 3. Clean up conflicting settings. These are no longer needed.
  networking.resolvconf.enable = false;
  networking.useHostResolvConf = false;
  networking.useDHCP = false;
  networking.interfaces = { };

  # 4. Keep cloud-init configuration minimal.
  services.cloud-init = {
    enable = true;
    network.enable = true;
    settings.datasource_list = [ "NoCloud" ];
  };
}

