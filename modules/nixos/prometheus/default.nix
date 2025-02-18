{ lib, config, pkgs, ... }: {

  options = {
    mine.prometheus.enable =
      lib.mkEnableOption "enable prometheus";
  };

  config = lib.mkIf config.mine.prometheus.enable {

    services.prometheus = {
      enable = true;
      port = 9001;
    };

    environment.systemPackages = with pkgs; [ prometheus ];
  };
}
