{ lib, config, ... }: {

  options = {
    mine.networkmanager.enable =
      lib.mkEnableOption "enable networkmanager";
  };

  config = lib.mkIf config.mine.networkmanager.enable {
    networking.networkmanager.enable = true;
  };
}
