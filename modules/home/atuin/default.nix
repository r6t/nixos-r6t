{ lib, config, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.atuin;

  # Shared atuin configuration
  atuinConfig = {
    programs.atuin = {
      enable = true;
      # causes bind -k warning on fish >4.1
      # atuin 18.8.0 + fish 4.1.2 still throwing -k warnings
      enableFishIntegration = true;
      flags = [ "--disable-up-arrow" ];
    };
  };

in
{
  options.mine.home.atuin.enable =
    lib.mkEnableOption "enable atuin in home-manager";

  config = lib.mkIf cfg.enable (
    if isNixOS then {
      # NixOS mode: configure via home-manager.users wrapper
      home-manager.users.${userConfig.username} = atuinConfig;
    } else
    # Standalone home-manager mode: configure directly
      atuinConfig
  );
}
