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
          qemu.package = pkgs.qemu_kvm;
          qemu.options = [ "-L /run/current-system/sw/bin/virtiofsd" ];
        };
      };
      users.users.r6t.extraGroups = [ "libvirtd" ];
      services.libvirtd = {
        enable = true;
        extraConfig = ''
          unix_sock_group = "libvirt"
          unix_sock_rw_perms = "0770"
          auth_unix_rw = "none"
        '';
      };
      programs.virt-manager.enable = true;
  };
}