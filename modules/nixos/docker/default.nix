{ lib, config, pkgs, ... }:
{

  options = {
    mine.docker.enable =
      lib.mkEnableOption "enable docker, used inside LXC";
  };

  config = lib.mkIf config.mine.docker.enable {
    virtualisation.docker = {
      autoPrune.enable = true;
      daemon.settings = {
        experimental = true;
        # slow but was having trouble getting this done with a better storage-driver docker in LXC
        "storage-driver" = "vfs";
      };
      enable = true;
      enableOnBoot = true;
      rootless = {
        # moving away from rootless docker when I switched to run docker workloads in dedicated LXCs
        enable = false;
        # setSocketVariable = true;
      };
    };
    environment.systemPackages = with pkgs; [
      docker-compose
    ];
  };
}
