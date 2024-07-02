{ lib, config, pkgs, ... }: { 

    options = {
      mine.libvirtd.enable =
        lib.mkEnableOption "enable libvirtd QEMU/KVM virt-manager";
    };

    config = lib.mkIf config.mine.libvirtd.enable { 
      virtualisation = {
        libvirtd = {
          enable = true;
          qemu.ovmf.enable = true;
        };
      };
      users.users.r6t.extraGroups = [ "libvirtd" ];
      programs.virt-manager.enable = true;
  };
}