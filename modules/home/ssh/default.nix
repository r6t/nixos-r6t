{ lib, config, userConfig, ... }: {

  options = {
    mine.home.ssh.enable =
      lib.mkEnableOption "configure ssh in home-manager";
  };

  config = lib.mkIf config.mine.home.ssh.enable
    (import ./config.nix { inherit userConfig; });
}
