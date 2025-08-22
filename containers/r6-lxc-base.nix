{ pkgs, modulesPath, ... }:
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
    ethtool
    fd
    git
    git-remote-codecommit
    gnumake
    iproute2
    lshw
    neovim
    netcat
    nettools
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
  services.resolved.enable = true;

  services.tailscale.enable = true;
  networking.firewall.trustedInterfaces = [ "tailscale0" ];
  # 3. Clean up conflicting settings. These are no longer needed.
  networking.resolvconf.enable = false;
  networking.useHostResolvConf = false;
  networking.useDHCP = false;
  networking.interfaces = { };

  # keep cloud-init configuration minimal.
  services.cloud-init = {
    enable = true;
    network.enable = true;
    settings.datasource_list = [ "NoCloud" ];
  };

  # Default shell: fish
  programs.fish.enable = true;
  users.users.root.shell = pkgs.fish;
}

