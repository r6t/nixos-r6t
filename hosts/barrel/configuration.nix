{ ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  fileSystems."/mnt/zfskey" = {
    device = "/dev/disk/by-uuid/213b225c-366b-4577-a56f-366fe577d482";
    fsType = "ext4";
    options = [ "noatime" ];
  };

  networking = {
    hostId = "eb5912c9";
    enableIPv6 = false;
    hostName = "barrel";
    defaultGateway.interface = "eno2";

    interfaces = {
      # Lower port unused
      eno1.useDHCP = false;
      # Upper port static IP
      eno2 = {
        useDHCP = false;
        ipv4.addresses = [{
          address = "192.168.6.4";
          prefixLength = 24;
        }];
      };
    };

    firewall = {
      enable = true;
      checkReversePath = false;
    };
  };

  system.stateVersion = "23.11";

  systemd.tmpfiles.rules = [
    "d /mnt/barrel-pool 0755 r6t users -"
    "d /mnt/zfskey 0755 root root -"
  ];

  # modules/
  mine = {
    zfs-pool = {
      barrel-pool = {
        poolName = "barrel-pool";
        keyFile = "/mnt/zfskey/barrel-pool.key";
        after = [ "mnt-zfskey.mount" ];
        requires = [ "mnt-zfskey.mount" ];

        delegation = {
          enableReceive = true; # Allow r6t to receive snapshots without sudo
        };

        snapshots = {
          enable = false; # Snapshots arrive via replication from crown
        };
      };
    };
  };
}
