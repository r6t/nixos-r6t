{ lib, config, pkgs, ... }: { 

    options = {
      mine.thunderbay.enable =
        lib.mkEnableOption "unlock and mount drives in thunderbay box";
    };

    config = lib.mkIf config.mine.thunderbay.enable { 
      environment.etc.crypttab = {
        enable = true;
        text = ''
          8TB-A1 UUID=3c429d84-386d-4272-8739-7bd2dcde1159 /home/r6t/luks-keys/tbay/8tba luks
          8TB-D1 UUID=5b66a482-036d-4a76-8cec-6ad15fe2360c /home/r6t/luks-keys/tbay/8tbb luks
          8TB-C1 UUID=cb067a1e-147b-4052-b561-e2c16c31dd0e /home/r6t/luks-keys/tbay/8tbd luks
          4TB-B1 UUID=b214dac6-7a73-4e53-9f89-b1ae82c0c625 /home/r6t/luks-keys/tbay/4tbe luks
          2TB-E1 UUID=544de6c8-1332-47d2-a38f-ed67d4db46e4 /home/r6t/luks-keys/tbay/2tbf luks
        '';
      };

      fileSystems."/home/r6t/external-ssd/8TB-A" = {
        device = "/dev/mapper/8TB-A1";
        fsType = "ext4";
        options = [
          "noauto"
          "x-systemd.automount"
          "x-systemd.requires=cryptsetup.target"
        ];
      };
      fileSystems."/home/r6t/external-ssd/4TB-B" = {
        device = "/dev/mapper/4TB-B1";
        fsType = "ext4";
        options = [
          "noauto"
          "x-systemd.automount"
          "x-systemd.requires=cryptsetup.target"
        ];
      };
      fileSystems."/home/r6t/external-ssd/8TB-C" = {
        device = "/dev/mapper/8TB-C1";
        fsType = "ext4";
        options = [
          "noauto"
          "x-systemd.automount"
          "x-systemd.requires=cryptsetup.target"
        ];
      };
      fileSystems."/home/r6t/external-ssd/8TB-D" = {
        device = "/dev/mapper/8TB-D1";
        fsType = "ext4";
        options = [
          "noauto"
          "x-systemd.automount"
          "x-systemd.requires=cryptsetup.target"
        ];
      };
      fileSystems."/home/r6t/external-ssd/2TB-E" = {
        device = "/dev/mapper/2TB-E1";
        fsType = "ext4";
        options = [
          "noauto"
          "x-systemd.automount"
          "x-systemd.requires=cryptsetup.target"
        ];
      };
    };
  } 
