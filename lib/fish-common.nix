{
  fishPrompt = ''
    function fish_prompt
      # Show user and hostname with muted hostname
      echo -n (set_color 3ddbd9)$USER(set_color normal)@(set_color 525252)(hostname)
      echo -n (set_color 78a9ff)" "(prompt_pwd)
      
      # Git status with git icon
      echo -n (set_color be95ff)" 🌱 "
      if git rev-parse --is-inside-work-tree &>/dev/null
        echo -n (git branch --show-current)
      else
        echo -n "<none>"
      end
      
      # Nix shell status with snowflake
      echo -n (set_color 82cfff)" ❄ "
      if test -n "$IN_NIX_SHELL"
        if test -n "$IN_NIX_SHELL_NAME"
          echo -n $IN_NIX_SHELL_NAME
        else
          echo -n (basename $name)
        end
      else
        echo -n "<none>"
      end
      
      # Python venv with snake icon
      echo -n (set_color 42be65)" 🐍 "
      if test -n "$VIRTUAL_ENV"
        echo -n (basename $VIRTUAL_ENV)
      else
        echo -n "<none>"
      end
      
      echo
      echo -n (set_color normal)" > "
    end
  '';
}

