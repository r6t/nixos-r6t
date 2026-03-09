{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.makemkv.enable =
      lib.mkEnableOption "enable makemkv";
  };

  config = lib.mkIf config.mine.home.makemkv.enable {
    boot.kernelModules = [
      "sg"
    ];
    home-manager.users.${userConfig.username}.home.packages = with pkgs; [ makemkv ];
    users.users.${userConfig.username}.extraGroups = [ "cdrom" ];
  };
}
