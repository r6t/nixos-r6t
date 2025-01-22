{
  fishPrompt = ''
    function fish_prompt
      # Get hostname and create abbreviation
      set -l host (hostname)
      set -l short_host (string sub -l 1 $host)""(string sub -s -1 $host)

      # User, abbreviated hostname, cwd
      echo -n (set_color 3ddbd9)$USER(set_color normal)@(set_color 8d8d8d)$short_host
      echo -n (set_color 78a9ff)" "(prompt_pwd)

      # Git branch indicator
      if git rev-parse --is-inside-work-tree &>/dev/null
        set -l branch (git branch --show-current)
        # Smart branch abbreviation - only abbreviate if contains / or -
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

      # Nix devshell indicator
      if test -n "$IN_NIX_SHELL"
        echo -n (set_color 82cfff)" ❄ "$DEVSHELL_NAME
      end

      # Python venv indicator
      if test -n "$VIRTUAL_ENV"
        echo -n (set_color 42be65)" 🐍"
      end

      echo -n (set_color normal)" > "
    end
  '';
}

