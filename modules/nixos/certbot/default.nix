{ lib, config, pkgs, ... }: {

  options = {
    mine.certbot.enable =
      lib.mkEnableOption "enable certbot";
  };

  config = lib.mkIf config.mine.certbot.enable {
    environment.systemPackages = with pkgs; [ certbot ];
  };
}

