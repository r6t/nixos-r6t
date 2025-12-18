{ lib, config, pkgs, ... }: {

  options = {
    mine.asusctl.enable =
      lib.mkEnableOption "enable asusctl";
  };

  config = lib.mkIf config.mine.asusctl.enable {
    environment.systemPackages = with pkgs; [ asusctl ];
    services.asusd = {
      enable = true;
      enableUserService = true;
    };
  };
}
