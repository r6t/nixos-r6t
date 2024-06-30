{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.libvirtd.enable =
        lib.mkEnableOption "user-level virtualization config";
    };

    config = lib.mkIf config.mine.home.libvirtd.enable { 
      home-manager.users.r6t.home.dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = ["qemu:///silvertorch.ryan.magic.internal"];
          uris = ["qemu:///silvertorch.ryan.magic.internal"];
        };
      };

      users.users.r6t.extraGroups = [ "libvirtd" ];
    };
}