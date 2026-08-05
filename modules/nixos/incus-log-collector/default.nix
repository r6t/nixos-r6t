{ lib, config, pkgs, ... }:

{
  options.mine.incus-log-collector = {
    enable = lib.mkEnableOption "collect journald logs from incus containers";
  };

  config = lib.mkIf config.mine.incus-log-collector.enable (import ./config.nix { inherit pkgs; });
}
