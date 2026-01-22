{ lib, config, pkgs, userConfig, ... }:

let
  cfg = config.mine.home.fish;
  homeDir = userConfig.homeDirectory;
  
  # Pure home-manager fish configuration
  fishConfig = {
    home.packages = with pkgs; [
      bat
      fishPlugins.forgit
      fzf
      lsd
      pandoc
      ripgrep
    ] ++ lib.optionals pkgs.stdenv.isLinux [
      fishPlugins.fzf-fish
    ];

    programs.fish = {
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
            set -l flake_path "${homeDir}/git/nixos-r6t"
            
            if not test -d "$flake_path"
              echo "Error: No flake found at $flake_path"
              return 1
            end
            
            set -l shell_name $argv[1]
            if test -z "$shell_name"
                nix develop $flake_path# --command fish
            else
                nix develop "$flake_path#$shell_name" --command fish
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

        fish_right_prompt = {
          body = ''
            # AWS credentials indicator
            set -l aws_indicator ""
            
            # Check for custom profile name first (set by 'i' function)
            if test -n "$AWS_PROFILE_NAME"
              set aws_indicator $AWS_PROFILE_NAME
            else if test -n "$AWS_DEFAULT_PROFILE"
              set aws_indicator $AWS_DEFAULT_PROFILE
            else if test -n "$AWS_PROFILE"
              set aws_indicator $AWS_PROFILE
            else if test -n "$AWS_SESSION_TOKEN"; or test -n "$AWS_ACCESS_KEY_ID"
              # Fallback for federated credentials without profile name
              set aws_indicator "federated"
            end
            
            if test -n "$aws_indicator"
              # Use oxocarbon yellow (palette 3) for background, black for text
              echo -n (set_color 262626 --background ffe97b)" ☁ $aws_indicator "(set_color normal)
            end
          '';
        };
      } // lib.optionalAttrs pkgs.stdenv.isLinux {
        # NixOS-specific rebuild function
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
      };

      interactiveShellInit = ''
        # Universal user paths
        fish_add_path $HOME/.nix-profile/bin
        fish_add_path $HOME/.local/bin
        
        # Ensure nix command is available (Determinate Nix installation)
        # This is especially important in devshells which strip system PATH
        fish_add_path /nix/var/nix/profiles/default/bin
      '';
    };

    programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
in
{
  options.mine.home.fish.enable =
    lib.mkEnableOption "enable fish in home-manager";

  # Pure home-manager configuration - wraps in home-manager.users.xxx
  config = lib.mkIf cfg.enable {
    home-manager.users.${userConfig.username} = fishConfig;
  };
}
