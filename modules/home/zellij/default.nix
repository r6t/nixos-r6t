{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.zellij;

  # Oxocarbon palette (dark) — RGB values for zellij semantic theme components
  # base00 #161616  base01 #262626  base02 #393939  base03 #525252
  # base04 #dde1e6  base05 #f2f4f8  base07 #08bdba  base08 #3ddbd9
  # base09 #78a9ff  base10 #ee5396  base11 #33b1ff  base12 #ff7eb6
  # base13 #42be65  base14 #be95ff  base15 #82cfff
  oxocarbonTheme = ''
    themes {
        oxocarbon {
            // ribbon = mode indicators and tabs in the status/compact bar
            ribbon_selected {
                // active tab / active mode: teal bg, dark text
                base 22 22 22
                background 8 189 186
                emphasis_0 238 83 150
                emphasis_1 255 126 182
                emphasis_2 66 190 101
                emphasis_3 120 169 255
            }
            ribbon_unselected {
                // inactive tabs / other modes: base01 sits above violet-tinted bar
                // emphasis_1 = alternate tab bg — base02 (#393939) instead of hot pink
                base 221 225 230
                background 38 38 38
                emphasis_0 238 83 150
                emphasis_1 57 57 57
                emphasis_2 66 190 101
                emphasis_3 120 169 255
            }
            // bare text (Ctrl/Alt modifier labels etc.)
            // background fills the bar — dark violet tint (#1c1a26) lifts it off
            // the terminal (#161616) without screaming for attention
            text_unselected {
                base 130 207 255
                background 28 26 38
                // emphasis_0 = non-Normal/non-Locked modes (TAB, PANE, RESIZE, etc.)
                // violet (#be95ff) — distinct from Normal (green) and active tab (teal)
                emphasis_0 190 149 255
                // emphasis_1 = unused in compact-bar currently, keep as blue
                emphasis_1 120 169 255
                // emphasis_2 = NORMAL mode indicator
                emphasis_2 66 190 101
                // emphasis_3 = LOCKED mode indicator
                emphasis_3 238 83 150
            }
            text_selected {
                base 242 244 248
                background 57 57 57
                emphasis_0 8 189 186
                emphasis_1 120 169 255
                emphasis_2 66 190 101
                emphasis_3 238 83 150
            }
            // table components (session manager etc.)
            table_title {
                base 8 189 186
                background 38 38 38
                emphasis_0 120 169 255
                emphasis_1 66 190 101
                emphasis_2 255 126 182
                emphasis_3 190 149 255
            }
            table_cell_unselected {
                base 221 225 230
                background 38 38 38
                emphasis_0 8 189 186
                emphasis_1 120 169 255
                emphasis_2 66 190 101
                emphasis_3 238 83 150
            }
            table_cell_selected {
                base 242 244 248
                background 57 57 57
                emphasis_0 8 189 186
                emphasis_1 120 169 255
                emphasis_2 66 190 101
                emphasis_3 238 83 150
            }
            // list components (search results etc.)
            list_unselected {
                base 221 225 230
                background 22 22 22
                emphasis_0 8 189 186
                emphasis_1 120 169 255
                emphasis_2 66 190 101
                emphasis_3 238 83 150
            }
            list_selected {
                base 242 244 248
                background 57 57 57
                emphasis_0 8 189 186
                emphasis_1 120 169 255
                emphasis_2 66 190 101
                emphasis_3 238 83 150
            }
            // pane frames
            frame_unselected {
                base 57 57 57
                background 22 22 22
                emphasis_0 82 82 82
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            frame_selected {
                base 8 189 186
                background 22 22 22
                emphasis_0 120 169 255
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            frame_highlight {
                base 255 126 182
                background 22 22 22
                emphasis_0 238 83 150
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            // exit code indicators (zellij run panes)
            exit_code_success {
                base 66 190 101
                background 0
                emphasis_0 8 189 186
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            exit_code_error {
                base 238 83 150
                background 0
                emphasis_0 255 126 182
                emphasis_1 0
                emphasis_2 0
                emphasis_3 0
            }
            multiplayer_user_colors {
                player_1 255 126 182
                player_2 120 169 255
                player_3 0
                player_4 66 190 101
                player_5 61 219 217
                player_6 0
                player_7 238 83 150
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
