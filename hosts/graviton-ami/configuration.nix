{ lib, inputs, ... }:

{
  imports = [
    inputs.home-manager.nixosModules.home-manager
    "${inputs.nixpkgs}/nixos/modules/virtualisation/amazon-image.nix"
    ../../modules/multi-arch.nix
  ];

  time.timeZone = "Etc/UTC";
  networking = {
    hostName = "graviton-ami";
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
}

