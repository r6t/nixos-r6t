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

  systemd.network.enable = true;

  networking = {
    firewall.trustedInterfaces = [ "tailscale0" ];
    resolvconf.enable = false;
    useHostResolvConf = false;
    useDHCP = false;
    useNetworkd = true;
    interfaces = { };
    extraHosts = ''
      192.168.6.9 headscale.r6t.io
    '';
  };

  services = {
    cloud-init = {
      enable = true;
      network.enable = true;
      settings.datasource_list = [ "NoCloud" ];
    };
    tailscale.enable = true;
    resolved.enable = true;
  };

  programs.fish.enable = true;
  users.users.root.shell = pkgs.fish;
}

