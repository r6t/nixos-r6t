{ lib, config, pkgs, ... }: { 

    options = {
      mine.libvirtd.enable =
        lib.mkEnableOption "enable libvirtd QEMU/KVM virt-manager";
    };

    config = lib.mkIf config.mine.libvirtd.enable { 
      environment.systemPackages = with pkgs; [
        virtiofsd
      ];
      virtualisation = {
        libvirtd = {
          enable = true;
          qemu.ovmf.enable = true;
          package = pkgs.qemu_kvm;
          extraOptions = [ "-L /run/current-system/sw/bin/virtiofsd" ];
        };
      };
      users.users.r6t.extraGroups = [ "libvirtd" ];
      programs.virt-manager.enable = true;
  };
}