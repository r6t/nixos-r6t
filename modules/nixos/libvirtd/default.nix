{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.libvirtd.enable =
      lib.mkEnableOption "enable libvirtd, QEMU/KVM, virt-manager";
  };

  config = lib.mkIf config.mine.libvirtd.enable {
    environment.systemPackages = with pkgs; [
      kvmtool
      virtiofsd
      usbutils
      libusb1
      pkg-config
      bridge-utils
      qemu
    ];
    virtualisation = {
      libvirtd = {
        enable = true;
        qemu.ovmf.enable = true;
      };
    };
    users.users.${userConfig.username}.extraGroups = [ "libvirtd" "plugdev" "dialout" ];
    programs.virt-manager.enable = true;
  };
}
