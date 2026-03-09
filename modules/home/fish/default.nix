{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.fish;
  homeDir = userConfig.homeDirectory;

  # Pure home-manager fish configuration
  fishConfig = {
    home.packages = with pkgs; [
      bat
      fd
      fishPlugins.forgit
      fzf
      gnused
      jq
      lsd
      pandoc
      ripgrep
      tree
      yq
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
        v = "nvim";
      };

      shellAbbrs = {
        cat = "bat";
        # git staging / inspection
        ga = "git add";
        gb = "nvim -c 'Git branch'";
        gc = "nvim -c 'Git commit'";
        gd = "nvim -c 'Gdiffsplit'";
        gds = "nvim -c 'Gdiffsplit --staged'";
        gf = "nvim -c 'Git fetch'";
        gg = "nvim -c Git";
        gl = "nvim -c 'Git log --oneline --graph --decorate'";
        gp = "nvim -c 'Git push'";
        gs = "nvim -c Git";
        # rebase workflow
        gri = "nvim -c 'Git rebase -i'";
        grc = "nvim -c 'Git rebase --continue'";
        gra = "nvim -c 'Git rebase --abort'";
        grs = "nvim -c 'Git rebase --skip'";
        # merge workflow
        gm = "nvim -c 'Git merge'";
        gma = "nvim -c 'Git merge --abort'";
        # conflict resolution: open 3-way diff on conflicted file
        gx = "nvim -c 'Gdiffsplit!'";
        # stash
        gst = "nvim -c 'Git stash'";
        gstp = "nvim -c 'Git stash pop'";
        gstl = "nvim -c 'Git stash list'";
        # cherry-pick
        gcp = "nvim -c 'Git cherry-pick'";
      };

      functions = {
        nd = {
          description = "Enter a named nixos-r6t devshell (aws, media, etc). Default devshell auto-activates via direnv in ~/git/nixos-r6t.";
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

        i = {
          description = "Switch AWS profile (or clear to default)";
          body = ''
            set -l profile_name $argv[1]
            if test -z "$profile_name"
              set -e AWS_PROFILE
              set -e AWS_ACCESS_KEY_ID
              set -e AWS_SECRET_ACCESS_KEY
              set -e AWS_SESSION_TOKEN
              set -e AWS_PROFILE_NAME
              echo "✓ Cleared AWS profile, using default"
            else if grep -q "^\[profile $profile_name\]" ~/.aws/config
              set -gx AWS_PROFILE $profile_name
              set -e AWS_ACCESS_KEY_ID
              set -e AWS_SECRET_ACCESS_KEY
              set -e AWS_SESSION_TOKEN
              set -e AWS_PROFILE_NAME
              echo "✓ Switched to AWS profile: $profile_name"
            else
              echo "❌ Profile '$profile_name' not found in ~/.aws/config"
              echo "Run 'ils' to list available profiles."
              return 1
            end
          '';
        };

        ils = {
          description = "List AWS profiles from ~/.aws/config";
          body = ''
            echo "Available AWS profiles (locally configured):"
            grep "^\[profile " ~/.aws/config | sed 's/\[profile \(.*\)\]/  - \1/'
          '';
        };

        iunset = {
          description = "Clear all AWS credentials and profile from environment";
          body = ''
            set -e AWS_PROFILE
            set -e AWS_ACCESS_KEY_ID
            set -e AWS_SECRET_ACCESS_KEY
            set -e AWS_SESSION_TOKEN
            set -e AWS_PROFILE_NAME
            echo "✓ Cleared AWS credentials"
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
              # No profile env var set but credentials present — use "default" profile
              set aws_indicator "default"
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

  config = lib.mkIf cfg.enable (
    if isNixOS
    then {
      # NixOS: wrap in home-manager.users
      home-manager.users.${userConfig.username} = fishConfig;
    }
    else fishConfig # Standalone home-manager: configure directly
  );
}
