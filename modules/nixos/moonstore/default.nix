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
      description = "Unlock and mount moonstore ssd";
      after = [
        "network.target"
        "cryptsetup.target"
      ];
      requires = [
        "network.target"
        "cryptsetup.target"
      ];
      wantedBy = [ "local-fs.target" ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStartPre = [
          "${pkgs.cryptsetup}/bin/cryptsetup luksOpen --key-file=/etc/nixos/moonstore-luks /dev/nvme0n1p1 moonstore"
        ];
        ExecStart = [
          "${pkgs.util-linux}/bin/mount /dev/mapper/moonstore /mnt/moonstore"
        ];
        ExecStop = [
          "${pkgs.util-linux}/bin/umount /mnt/moonstore"
          "${pkgs.cryptsetup}/bin/cryptsetup luksClose moonstore"
        ];
      };
    };
  };
}

