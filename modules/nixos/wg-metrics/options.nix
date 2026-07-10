{ lib, ... }:

{
  options.mine.wg-metrics = {
    enable = lib.mkEnableOption "WireGuard metrics collection from incus exit node containers";

    interval = lib.mkOption {
      type = lib.types.str;
      default = "300s";
      description = "How often to poll WireGuard stats (systemd OnUnitActiveSec format)";
    };

    instanceMapFile = lib.mkOption {
      type = lib.types.path;
      description = "Path to instance_map.json that maps incus instance names to image aliases";
    };
  };
}
