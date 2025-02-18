{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.libvirtd.enable =
      lib.mkEnableOption "enable libvirtd QEMU/KVM virt-manager";
  };

  config = lib.mkIf config.mine.libvirtd.enable {
    environment.systemPackages = with pkgs; [
      virtiofsd
      usbutils
      libusb1
      pkg-config
      bridge-utils
    ];
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu.ovmf.enable = true;
        # package = pkgs.qemu_kvm;
      };
    };
    users.users.${userConfig.username}.extraGroups = [ "libvirtd" "plugdev" "dialout" ];
    programs.virt-manager.enable = true;
  };
}
