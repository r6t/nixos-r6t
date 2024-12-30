{ lib, config, pkgs, ... }: {

  options = {
    mine.sshfs.enable =
      lib.mkEnableOption "enable and configure sshfs";
  };

  config = lib.mkIf config.mine.sshfs.enable {
    environment.systemPackages = with pkgs; [ sshfs ];
  };
}
