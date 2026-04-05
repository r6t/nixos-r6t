{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.zellij;
  wrapHome = import ../../lib/mkPortableHomeConfig.nix { inherit isNixOS userConfig; };
  p = (import ../../lib/palette.nix).zellijRgb;

  # Oxocarbon theme — colors from modules/lib/palette.nix
  oxocarbonTheme = ''
    themes {
        oxocarbon {
            // ribbon = mode indicators and tabs in the status/compact bar
            ribbon_selected {
                // active tab / active mode: teal bg, dark text
                base ${p.base00}
                background ${p.teal}
                emphasis_0 ${p.pink}
                emphasis_1 ${p.lightpink}
                emphasis_2 ${p.green}
                emphasis_3 ${p.blue}
            }
            ribbon_unselected {
                // inactive tabs / other modes: base01 sits above violet-tinted bar
                // emphasis_1 = alternate tab bg — base02 instead of hot pink
                base ${p.base04}
                background ${p.base01}
                emphasis_0 ${p.pink}
                emphasis_1 ${p.base02}
                emphasis_2 ${p.green}
                emphasis_3 ${p.blue}
            }
            // bare text (Ctrl/Alt modifier labels etc.)
            // background fills the bar — dark violet tint lifts it off
            // the terminal without screaming for attention
            text_unselected {
                base ${p.lightblue}
                background ${p.darkviolet}
                // emphasis_0 = non-Normal/non-Locked modes (TAB, PANE, RESIZE, etc.)
                // violet — distinct from Normal (green) and active tab (teal)
                emphasis_0 ${p.violet}
                // emphasis_1 = unused in compact-bar currently, keep as blue
                emphasis_1 ${p.blue}
                // emphasis_2 = NORMAL mode indicator
                emphasis_2 ${p.green}
                // emphasis_3 = LOCKED mode indicator
                emphasis_3 ${p.pink}
            }
            text_selected {
                base ${p.base05}
                background ${p.base02}
                emphasis_0 ${p.teal}
                emphasis_1 ${p.blue}
                emphasis_2 ${p.green}
                emphasis_3 ${p.pink}
            }
            // table components (session manager etc.)
            table_title {
                base ${p.teal}
                background ${p.base01}
                emphasis_0 ${p.blue}
                emphasis_1 ${p.green}
                emphasis_2 ${p.lightpink}
                emphasis_3 ${p.violet}
            }
            table_cell_unselected {
                base ${p.base04}
                background ${p.base01}
                emphasis_0 ${p.teal}
                emphasis_1 ${p.blue}
                emphasis_2 ${p.green}
                emphasis_3 ${p.pink}
            }
            table_cell_selected {
                base ${p.base05}
                background ${p.base02}
                emphasis_0 ${p.teal}
                emphasis_1 ${p.blue}
                emphasis_2 ${p.green}
                emphasis_3 ${p.pink}
            }
            // list components (search results etc.)
            list_unselected {
                base ${p.base04}
                background ${p.base00}
                emphasis_0 ${p.teal}
                emphasis_1 ${p.blue}
                emphasis_2 ${p.green}
                emphasis_3 ${p.pink}
            }
            list_selected {
                base ${p.base05}
                background ${p.base02}
                emphasis_0 ${p.teal}
                emphasis_1 ${p.blue}
                emphasis_2 ${p.green}
                emphasis_3 ${p.pink}
            }
            // pane frames
            frame_unselected {
                base ${p.base02}
                background ${p.base00}
                emphasis_0 ${p.base03}
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            frame_selected {
                base ${p.teal}
                background ${p.base00}
                emphasis_0 ${p.blue}
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            frame_highlight {
                base ${p.lightpink}
                background ${p.base00}
                emphasis_0 ${p.pink}
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            // exit code indicators (zellij run panes)
            exit_code_success {
                base ${p.green}
                background 0
                emphasis_0 ${p.teal}
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            exit_code_error {
                base ${p.pink}
                background 0
                emphasis_0 ${p.lightpink}
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            multiplayer_user_colors {
                player_1 ${p.lightpink}
                player_2 ${p.blue}
                player_3 0
                player_4 ${p.green}
                player_5 ${p.cyan}
                player_6 0
                player_7 ${p.pink}
                player_8 0
                player_9 0
                player_10 0
            }
        }
    }
  '';

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
      extraConfig = oxocarbonTheme;
      settings = {
        show_startup_tips = false;
        on_force_close = "detach";
        simplified_ui = true;
        session_name = "main-shell";
        attach_to_session = true;
        hide_tabs_bar_when_one_tab = true;
        default_shell = "${pkgs.fish}/bin/fish";
        default_layout = "custom-compact-top";
        pane_frames = true;
        scrollback_editor = "${pkgs.neovim}/bin/nvim";
        theme = "oxocarbon";
        keybinds = {
          unbind = [ "Ctrl g" "Ctrl p" "Ctrl n" "Ctrl t" "Ctrl s" "Ctrl o" "Ctrl m" ];
          normal = {
            "bind \"Super g\"" = { SwitchToMode._args = [ "Locked" ]; };
            "bind \"Super p\"" = { SwitchToMode._args = [ "Pane" ]; };
            "bind \"Super r\"" = { SwitchToMode._args = [ "Resize" ]; };
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
            "bind \"Super g\"" = { SwitchToMode._args = [ "Normal" ]; };
          };
        };
      };
    };
  };

in
{
  options.mine.home.zellij.enable =
    lib.mkEnableOption "enable zellij in home-manager";

  config = lib.mkIf cfg.enable (wrapHome zellijConfig);
}
