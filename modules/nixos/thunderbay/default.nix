{ lib, config, pkgs,... }: {
  options = {
    mine.thunderbay.enable =
      lib.mkEnableOption "Unlock and mount drives in thunderbay box";
  };
  config = lib.mkIf config.mine.thunderbay.enable {
    fileSystems."/mnt/thunderkey" = {
      device = "/dev/disk/by-label/thunderkey";
      fsType = "ext4";
      options = [
        "noatime"
      ];
    };

    systemd.services.thunderbay = {
      enable = true;
      wantedBy = [ "multi-user.target" ];
      after = [ 
        "network.target" 
        "cryptsetup.target" 
        "mnt-thunderkey.mount" 
      ];
      requires = [ 
        "network.target" 
        "cryptsetup.target" 
        "mnt-thunderkey.mount" 
      ];
      serviceConfig = {
        Type = "oneshot";
        ExecStartPre = [
          ""
	  "/run/current-system/sw/bin/sleep 30"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksOpen --key-file=/mnt/thunderkey/8tba /dev/disk/by-uuid/3c429d84-386d-4272-8739-7bd2dcde1159 8TB-A1"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksOpen --key-file=/mnt/thunderkey/8tbb /dev/disk/by-uuid/5b66a482-036d-4a76-8cec-6ad15fe2360c 8TB-D1"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksOpen --key-file=/mnt/thunderkey/8tbd /dev/disk/by-uuid/cb067a1e-147b-4052-b561-e2c16c31dd0e 8TB-C1"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksOpen --key-file=/mnt/thunderkey/4tbe /dev/disk/by-uuid/b214dac6-7a73-4e53-9f89-b1ae82c0c625 4TB-B1"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksOpen --key-file=/mnt/thunderkey/2tbf /dev/disk/by-uuid/544de6c8-1332-47d2-a38f-ed67d4db46e4 2TB-E1"
        ];
        ExecStart = [
          ""
          "${pkgs.utillinux}/bin/mount /dev/mapper/8TB-A1 /home/r6t/external-ssd/8TB-A"
          "${pkgs.utillinux}/bin/mount /dev/mapper/4TB-B1 /home/r6t/external-ssd/4TB-B"
          "${pkgs.utillinux}/bin/mount /dev/mapper/8TB-C1 /home/r6t/external-ssd/8TB-C"
          "${pkgs.utillinux}/bin/mount /dev/mapper/8TB-D1 /home/r6t/external-ssd/8TB-D"
          "${pkgs.utillinux}/bin/mount /dev/mapper/2TB-E1 /home/r6t/external-ssd/2TB-E"
        ];
        ExecStopPost = [
          ""
          "${pkgs.utillinux}/bin/umount /home/r6t/external-ssd/2TB-E"
          "${pkgs.utillinux}/bin/umount /home/r6t/external-ssd/4TB-B"
          "${pkgs.utillinux}/bin/umount /home/r6t/external-ssd/8TB-A"
          "${pkgs.utillinux}/bin/umount /home/r6t/external-ssd/8TB-C"
          "${pkgs.utillinux}/bin/umount /home/r6t/external-ssd/8TB-D"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksClose 2TB-E1"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksClose 4TB-B1"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksClose 8TB-A1"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksClose 8TB-C1"
          "${pkgs.cryptsetup}/sbin/cryptsetup luksClose 8TB-D1"
        ];
        RemainAfterExit = true; # keep service alive after script runs
      };
    };
  };
}
