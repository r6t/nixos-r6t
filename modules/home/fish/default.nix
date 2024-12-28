{ lib, config, pkgs, userConfig, ... }:
let
  fishCommon = import ../../../lib/fish-common.nix;
in
{

  options = {
    mine.home.fish.enable =
      lib.mkEnableOption "enable fish in home-manager";
  };

  config = lib.mkIf config.mine.home.fish.enable {

    environment.systemPackages = with pkgs; [
      fishPlugins.fzf-fish
      fishPlugins.forgit
    ];
    programs = {
      fish.enable = true;
      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    };

    home-manager.users.${userConfig.username}.programs.fish = {
      enable = true;
      shellAliases = {
        "nvf" = "nvim $(fzf -m --preview='bat --color=always {}')";
        "Git" = "git status";
        "Gd" = "git diff";
        "Gds" = "git diff --staged";
      };
      functions = {
        dev = {
          description = "Use devShell - see flake.nix";
          body = "fish -c \"nix develop /home/r6t/git/nixos-r6t#$argv\"";
        };
      };
      interactiveShellInit = ''
        # Add pre-commit to PATH
        fish_add_path $HOME/.nix-profile/bin

        # Import common shell config, shared with devshells
        ${fishCommon.fishPrompt}
      '';
    };
  };
}
