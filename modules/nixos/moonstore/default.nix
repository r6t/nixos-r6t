{ lib, config, pkgs, ... }: {
  options = {
    mine.moonstore.enable =
      lib.mkEnableOption "Unlock and mount moonstore ssd";
  };
  config = lib.mkIf config.mine.moonstore.enable {
    # Ensure mount directories exist with proper permissions
    system.activationScripts.createMoonstoreDirs = ''
      mkdir -p /mnt/moonstore
      chmod 755 /mnt/moonstore
    '';

    systemd.services.moonstore = {
      enable = true;
      description = "Unlock moonstore LUKS";
      wantedBy = [ "multi-user.target" ];
      after = [
        "network.target"
        "cryptsetup.target"
      ];
      requires = [
        "network.target"
        "cryptsetup.target"
      ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        RequiresMountsFor = [ "/etc/nixos" ];
        ExecStart = [
          ''
            ${pkgs.bash}/bin/bash -c "
              set -ex
              ${pkgs.cryptsetup}/bin/cryptsetup luksOpen --key-file=/etc/nixos/moonstore-luks /dev/nvme0n1p1 moonstore || exit 1
              [ -e /dev/mapper/moonstore ] || exit 1
              ${pkgs.e2fsprogs}/bin/e2fsck -f /dev/mapper/moonstore || true
            "
          ''
        ];
        ExecStop = [
          ''
            ${pkgs.bash}/bin/bash -c "
              ${pkgs.util-linux}/bin/umount -l /mnt/moonstore || true
              ${pkgs.cryptsetup}/bin/cryptsetup luksClose moonstore || true
            "
          ''
        ];
      };
    };

    fileSystems."/mnt/moonstore" = {
      device = "/dev/mapper/moonstore";
      fsType = "ext4";
      options = [ "defaults" "noatime" ];
      depends = [ "moonstore.service" ];
    };
  };
}

