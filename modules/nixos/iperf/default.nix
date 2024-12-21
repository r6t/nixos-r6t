{ lib, config, pkgs, ... }: {

  options = {
    mine.iperf.enable =
      lib.mkEnableOption "enable iperf";
  };

  config = lib.mkIf config.mine.iperf.enable {
    environment.systemPackages = with pkgs; [ iperf ];
  };
}
