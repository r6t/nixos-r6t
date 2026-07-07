{ lib, config, pkgs, ... }:

{

  options = {
    mine.iperf.enable =
      lib.mkEnableOption "enable iperf";
  };

  config = lib.mkIf config.mine.iperf.enable (import ./config.nix { inherit pkgs; });
}
