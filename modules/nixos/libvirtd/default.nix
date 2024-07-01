{ lib, config, pkgs, ... }: { 

    options = {
      mine.libvirtd.enable =
        lib.mkEnableOption "enable libvirtd QEMU/KVM virt-manager";
    };

    config = lib.mkIf config.mine.libvirtd.enable { 
      virtualisation = {
        libvirtd = {
          enable = true;
          qemuOvmf = true;
          extraOptions = ["--listen"];
          tcpListen = true;
        };
      };
      programs.virt-manager.enable = true;
    };
}