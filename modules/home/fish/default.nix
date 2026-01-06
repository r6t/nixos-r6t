{ lib, config, pkgs, userConfig ? null, ... }:

let
  cfg = config.mine.home.fish;
  # Detect if we're in NixOS (userConfig passed) or standalone home-manager
  isNixOS = userConfig != null;
  # For standalone, get home directory from the home-manager config
  homeDir = if isNixOS then userConfig.homeDirectory else config.home.homeDirectory;

  # Shared fish configuration used in both modes
  fishConfig = {
    enable = true;

    shellAliases = {
      ".." = "cd ..";
      "..." = "cd ../..";
      bat = "bat --paging never";
      ls = "lsd";
      l = "lsd -l";
      ll = "lsd -la";
      lt = "lsd --tree";
      o = "opencode";
    };

    shellAbbrs = {
      cat = "bat";
      g = "git";
      ga = "git add";
      gb = "git branch";
      gc = "git commit -m";
      gd = "git diff";
      gds = "git diff --staged";
      gg = "git status";
      gl = "git log --oneline --graph --decorate";
      gp = "git push";
      gs = "git status";
    };

    functions = {
      nd = {
        description = "nix develop aka enter devshell";
        body = ''
          set flake_path "${homeDir}/git/nixos-r6t"
          if not test -d "$flake_path"
              echo "Error: Flake path not found at $flake_path"
              return 1
          end
          set -l shell_name $argv[1]
          if test -z "$shell_name"
              nix develop $flake_path#
          else
              nix develop "$flake_path#$shell_name"
          end
        '';
      };

      fish_prompt = {
        body = ''
          set -l host (hostname)
          set -l short_host (string sub -l 1 $host)""(string sub -s -1 $host)
          echo -n (set_color 3ddbd9)$USER(set_color normal)@(set_color 8d8d8d)$short_host
          echo -n (set_color 78a9ff)" "(prompt_pwd)
          if git rev-parse --is-inside-work-tree &>/dev/null
            set -l branch (git branch --show-current)
            if string match -q "*/*" $branch; or string match -q "*-*" $branch
              set -l short_branch (string replace -r '^([^/]+)/(.+)$' '$1/$2' $branch | \
                string replace -r '^([^/]+)/([^-]+)-(.+)$' '$1/$2-$3' | \
                string replace -r '([^/])[^/-]*' '$1' | \
                string replace -r '([^-])[^/-]*' '$1')
              echo -n (set_color be95ff)" 🌱 "$short_branch
            else
              echo -n (set_color be95ff)" 🌱 "$branch
            end
          end
          if test -n "$IN_NIX_SHELL"
            echo -n (set_color 82cfff)" ❄ "$DEVSHELL_NAME
          end
          if test -n "$VIRTUAL_ENV"
            echo -n (set_color 42be65)" 🐍"
          end
          echo -n (set_color normal)" > "
        '';
      };
    } // lib.optionalAttrs pkgs.stdenv.isLinux {
      # NixOS-specific rebuild function (Linux only)
      nrs = {
        description = "Run nixos-rebuild switch --flake for the current host.";
        body = ''
          set flake_path "${homeDir}/git/nixos-r6t"
          set current_hostname (hostname)
          echo "nixos-rebuild for: $current_hostname"
          echo "sudo nixos-rebuild switch --flake '$flake_path#$current_hostname'"
          sudo nixos-rebuild switch --flake "$flake_path#$current_hostname"
        '';
      };
    } // lib.optionalAttrs pkgs.stdenv.isDarwin {
      # macOS-specific rebuild function
      hms = {
        description = "Run home-manager switch --flake for standalone home-manager.";
        body = ''
          set flake_path "${homeDir}/git/nixos-r6t"
          echo "home-manager switch for: work"
          echo "home-manager switch --flake '$flake_path#work' --impure"
          home-manager switch --flake "$flake_path#work" --impure
        '';
      };
    };

    interactiveShellInit = ''
      set -x _PR_DISABLE_AI 1
      pay-respects fish --alias | source
      fish_add_path $HOME/.nix-profile/bin
      fish_add_path $HOME/.local/bin
    '';
  };

  # Shared packages used in both modes
  fishPackages = with pkgs; [
    bat
    fishPlugins.forgit
    lsd
    pandoc
    pay-respects
    ripgrep
  ] ++ lib.optionals pkgs.stdenv.isLinux [
    fishPlugins.fzf-fish # marked broken on darwin
  ];

in
{
  options.mine.home.fish.enable =
    lib.mkEnableOption "enable fish in home-manager";

  config = lib.mkIf cfg.enable (
    if isNixOS then {
      # NixOS mode: configure via home-manager.users wrapper
      programs = lib.mkIf pkgs.stdenv.isLinux {
        fish.enable = true;
        direnv = {
          enable = true;
          nix-direnv.enable = true;
        };
      };

      home-manager.users.${userConfig.username} = {
        home.packages = fishPackages;
        programs.fish = fishConfig;
      };
    } else {
      # Standalone home-manager mode: configure directly
      home.packages = fishPackages;
      programs.fish = fishConfig;
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
    }
  );
}
