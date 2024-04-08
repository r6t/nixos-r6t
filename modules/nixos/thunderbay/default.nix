{ lib, config, pkgs, ... }: { 

    options = {
      mine.thunderbay.enable =
        lib.mkEnableOption "unlock and mount drives in thunderbay box";
    };

    config = lib.mkIf config.mine.thunderbay.enable { 
      environment.etc.crypttab = {
        enable = true;
        text = ''
          8TB-A1 UUID=cb067a1e-147b-4052-b561-e2c16c31dd0e /home/r6t/luks-keys/tbay/8tba
        '';
      };

     #  boot.initrd.luks.devices = {
        # a8 = {
        #   device = "/dev/sda1";
        #   keyFile = "/home/r6t/luks-keys/tbay/8tba";
        #   allowDiscards = true;
        # };
        # b8 = {
        #   device = "/dev/sdb1";
        #   keyFile = "/home/r6t/luks-keys/tbay/8tbb";
        #   allowDiscards = true;
        # };
        # d8 = { device = "/dev/sdd1";
        #   keyFile = "/home/r6t/luks-keys/tbay/8tbd";
        #   allowDiscards = true;
        # };
        # e4 = { device = "/dev/sde1";
        #   keyFile = "/home/r6t/luks-keys/tbay/4tbe";
        #   allowDiscards = true;
        # };
        # f2 = { device = "/dev/sdf1";
        #   keyFile = "/home/r6t/luks-keys/tbay/2tbf";
        #   allowDiscards = true;
        # };
    #   };

      # fileSystems."/home/r6t/external-ssd/8TB-A" = {
      #   device = "/dev/mapper/8TB-A1";
      #   fsType = "ext4";
      # };
      # fileSystems."/home/r6t/external-ssd/8TB-B" = {
      #   device = "/dev/mapper/8TB-B1";
      #   fsType = "ext4";
      # };
      # fileSystems."/home/r6t/external-ssd/8TB-D" = {
      #   device = "/dev/mapper/8TB-D1";
      #   fsType = "ext4";
      # };
      # fileSystems."/home/r6t/external-ssd/4TB-E" = {
      #   device = "/dev/mapper/4TB-E1";
      #   fsType = "ext4";
      # };
      # fileSystems."/home/r6t/external-ssd/2TB-PRO" = {
      #   device = "/dev/mapper/2TB-F1";
      #   fsType = "ext4";
      # };
    };
  } 