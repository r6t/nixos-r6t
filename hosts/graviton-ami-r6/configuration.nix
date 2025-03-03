{ lib, inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    "${inputs.nixpkgs}/nixos/modules/virtualisation/amazon-image.nix"
    ../../modules/multi-arch.nix
  ];

  time.timeZone = "Etc/UTC";
  networking = {
    hostName = "graviton-ami-r6";
    enableIPv6 = true;
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
  };
  environment.etc."fstab".text = ''
    # Empty fstab for EC2 import process
    # NixOS handles mounts through the fileSystems option
  '';
  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ena" ]; # ena added with lines at bottom
  system.stateVersion = "23.11";
  services.chrony.enable = true;
  networking.timeServers = [ "169.254.169.123" ];
  services.amazon-ssm-agent.enable = true;
  security.sudo.wheelNeedsPassword = false;

  ## added troubleshooting lacking ENA support
  nixpkgs.config.allowUnfree = true;
  hardware.enableAllFirmware = true;
  networking.useNetworkd = lib.mkForce false;
  boot.kernelModules = [ "ena" ];

  mine = {
    docker.enable = false;
    localization.enable = true;
    env.enable = true;
    prometheus-node-exporter.enable = true;
    fzf.enable = true;
    nix.enable = true;
    nixpkgs.enable = true;
    ssh.enable = true;
    syncthing.enable = true;
    tailscale.enable = true;
    user.enable = true;
    home = {
      awscli.enable = true;
      fish.enable = true;
      git.enable = true;
      home-manager.enable = true;
      nixvim.enable = true;
      python3.enable = true;
      zellij.enable = true;
    };
  };
}

