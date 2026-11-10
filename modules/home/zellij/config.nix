{ userConfig, hostSlug ? "", isNixOS ? true, ... }:

let
  wrapHome = import ../../lib/mkPortableHomeConfig.nix { inherit isNixOS userConfig; };
  p = (import ../../lib/palette.nix).zellijRgb;

  # The one persistent session per host. Named for the host (fish-main-ja,
  # fish-main-ml) so `zellij ls` and the session manager stay readable when
  # sessions are open on several machines at once; see options.nix hostSlug.
  sessionName = "fish-main" + (if hostSlug == "" then "" else "-${hostSlug}");

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
in
wrapHome {
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
      env = {
        TERM = "xterm-256color";
      };
      show_startup_tips = false;
      on_force_close = "detach";
      simplified_ui = true;
      session_name = sessionName;
      attach_to_session = true;
      hide_tabs_bar_when_one_tab = true;
      # Resolved on PATH, NOT as a store path: a zellij server can outlive the
      # generation it started in (`sshz` sessions run for weeks), and a store
      # path it still holds open stops resolving after a switch + nix GC.
      default_shell = "fish";
      default_layout = "custom-compact-top";
      pane_frames = true;
      scrollback_editor = "nvim";
      theme = "oxocarbon";
      keybinds = {
        unbind = [
          "Ctrl g"
          "Ctrl p"
          "Ctrl n"
          "Ctrl t"
          "Ctrl s"
          "Ctrl o"
          "Ctrl m"
          # zellij 0.45 defaults that collide with what runs INSIDE the panes.
          "Ctrl q" # Quit: one keystroke kills the session and every job in it
          "Ctrl h" # Move mode: swallows nvim's ZellijNavigateLeft <C-h>
          "Ctrl b" # Tmux mode: swallows Claude Code's Ctrl+B (background a task)
          "Alt p" # TogglePaneInGroup: swallows Claude Code's Alt+P (switch model)
          "Alt Shift p" # ToggleGroupMarking, the other half of pane groups
          "Alt o" # MoveTab right: swallows Claude Code's Alt+O (fast mode)
          "Alt i" # MoveTab left, the pair of Alt o; Tab mode still moves tabs
        ];
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

  # Declared here rather than in the fish leaf because it needs this module's
  # session name. home-manager's fish module gates its own config on
  # programs.fish.enable, so this is inert on a host without fish.
  programs.fish.functions.sshz = {
    description = "ssh to a host and attach its persistent zellij session";
    wraps = "ssh";
    body = ''
      if test (count $argv) -eq 0
          echo "usage: sshz <host> [ssh args...]" >&2
          return 2
      end

      if not ssh-add -l >/dev/null 2>&1
          echo "sshz: local ssh-agent holds no keys; git on the remote host cannot push or sign." >&2
      end

      # The agent link gives panes a stable $SSH_AUTH_SOCK. A zellij server
      # keeps the environment of the connection that started it, and that
      # connection's socket dies on disconnect; relinking here means a
      # reattach hands every existing pane a live agent again.
      # Bare `zellij`, with no session named here: settings.session_name plus
      # attach_to_session on the REMOTE host decide which session this joins,
      # so the host owns its own name and this function works against any host
      # whose slug it cannot know.
      set -l script 'if [ -n "$SSH_AUTH_SOCK" ]; then ln -sfn "$SSH_AUTH_SOCK" "$HOME/.ssh/agent.sock"; fi; SSH_AUTH_SOCK="$HOME/.ssh/agent.sock"; export SSH_AUTH_SOCK; exec zellij'

      # `bash -lc`, and nothing about it is shell configuration: a LOGIN shell
      # is what sources the host's /etc profile, and that is what puts nix on
      # PATH so plain `zellij` resolves without a store or profile path.
      # sshd would otherwise run this through a NON-login shell with a bare
      # PATH. bash because every Linux host has one -- NixOS hosts here
      # install no zsh (modules/profiles/system-core/system-shell.nix), and
      # $SHELL cannot be used since fish would not parse this POSIX script.
      # Single-quoted so the outer shell passes the script through unexpanded.
      set -l remote "bash -lc '$script'"

      # -t: zellij is a full-screen TUI and needs a pty.
      # -A: git auth and commit signing on the remote host use the local agent,
      #     so no private key has to live there.
      ssh -t -A $argv "$remote"
      set -l rc $status

      switch $rc
          case 255 # ssh's own failure code, not zellij's
              echo "sshz: ssh failed to reach $argv[1]." >&2
          case 127 # remote: command not found
              echo "sshz: no zellij on $argv[1] (is nix installed and on its login PATH?)" >&2
      end

      return $rc
    '';
  };
}
