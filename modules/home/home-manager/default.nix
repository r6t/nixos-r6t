{ inputs, lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.home-manager.enable =
      lib.mkEnableOption "enable home-manager core config";
  };

  config = lib.mkIf config.mine.home.home-manager.enable
    (import ./config.nix { inherit inputs lib pkgs userConfig; });
}
