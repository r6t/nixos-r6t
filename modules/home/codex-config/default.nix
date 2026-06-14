{ config, lib, userConfig, ... }:

{
  options.mine.home.codex-config.enable =
    lib.mkEnableOption "Codex user guidance";

  config = lib.mkIf config.mine.home.codex-config.enable {
    # Codex binary provided via devshell
    home-manager.users.${userConfig.username}.home.file.".codex/AGENTS.md".source = ./AGENTS.md;
  };
}
