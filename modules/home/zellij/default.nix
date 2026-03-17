{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.zellij;

  # Shared zellij configuration
  zellijConfig = {
    xdg.configFile."zellij/layouts/custom-compact-top.kdl" = {
      source = ./custom-compact-top.kdl;
    };
    programs.zellij = {
      # does nothing and throws a warning when enableFishIntegration = false
      attachExistingSession = false;
      enable = true;
      # possible compat issues with latest fish
      enableFishIntegration = false;
      settings = {
        show_startup_tips = false;
        simplified_ui = true;
        hide_tabs_bar_when_one_tab = true;
        default_shell = "fish";
        default_layout = "custom-compact-top";
        pane_frames = false;
        copy_command = if pkgs.stdenv.isDarwin then "pbcopy" else "wl-copy";
        scrollback_editor = "nvim";
        theme = "oxocarbon";
        keybinds = {
          unbind = [ "Ctrl g" "Ctrl p" "Ctrl n" "Ctrl t" "Ctrl s" "Ctrl o" "Ctrl m" ];
          normal = {
            "bind \"Super z\"" = { SwitchToMode._args = [ "Locked" ]; };
            "bind \"Super p\"" = { SwitchToMode._args = [ "Pane" ]; };
            "bind \"Super n\"" = { SwitchToMode._args = [ "Resize" ]; };
            "bind \"Super t\"" = { SwitchToMode._args = [ "Tab" ]; };
            "bind \"Super s\"" = { SwitchToMode._args = [ "Scroll" ]; };
            "bind \"Super o\"" = { SwitchToMode._args = [ "Session" ]; };
            "bind \"Super m\"" = { SwitchToMode._args = [ "Move" ]; };
            "bind \"Alt n\"" = { NewPane = { }; };
            # Alt h/j/k/l: use zellij defaults (MoveFocusOrTab for h/l, MoveFocus for j/k)
            # Direct tab switching - no Tab mode needed
            "bind \"Alt 1\"" = { GoToTab = 1; };
            "bind \"Alt 2\"" = { GoToTab = 2; };
            "bind \"Alt 3\"" = { GoToTab = 3; };
            "bind \"Alt 4\"" = { GoToTab = 4; };
            "bind \"Alt 5\"" = { GoToTab = 5; };
            "bind \"Alt 6\"" = { GoToTab = 6; };
            "bind \"Alt 7\"" = { GoToTab = 7; };
            "bind \"Alt 8\"" = { GoToTab = 8; };
            "bind \"Alt 9\"" = { GoToTab = 9; };
            # Tab management
            "bind \"Alt t\"" = { NewTab = { }; };
            "bind \"Alt r\"" = { SwitchToMode._args = [ "RenameTab" ]; };
            # Alt [ / Alt ] left at defaults (PreviousSwapLayout / NextSwapLayout)
          };
          locked = {
            "bind \"Super z\"" = { SwitchToMode._args = [ "Normal" ]; };
          };
        };

        themes.oxocarbon = {
          fg = "#c6c6c6";
          bg = "#161616";
          black = "#161616";
          red = "#ee5396";
          green = "#42be65";
          yellow = "#08bdba";
          blue = "#78a9ff";
          magenta = "#ff7eb6";
          cyan = "#3ddbd9";
          white = "#c6c6c6";
          bright_black = "#393939";
          bright_red = "#ee5396";
          bright_green = "#42be65";
          bright_yellow = "#08bdba";
          bright_blue = "#78a9ff";
          bright_magenta = "#ff7eb6";
          bright_cyan = "#3ddbd9";
          bright_white = "#f4f4f4";
          orange = "#ff7eb6";
        };
      };
    };
  };

in
{
  options.mine.home.zellij.enable =
    lib.mkEnableOption "enable zellij in home-manager";

  config = lib.mkIf cfg.enable (
    if isNixOS then {
      # NixOS mode: configure via home-manager.users wrapper
      home-manager.users.${userConfig.username} = zellijConfig;
    } else
    # Standalone home-manager mode: configure directly
      zellijConfig
  );
}
