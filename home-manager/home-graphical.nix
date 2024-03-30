{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:

let
  appleEmojiFont = pkgs.stdenv.mkDerivation rec {
    pname = "apple-emoji-linux";
    version = "16.4-patch.1";
    src = pkgs.fetchurl {
      url = "https://github.com/samuelngs/apple-emoji-linux/releases/download/v${version}/AppleColorEmoji.ttf";
      sha256 = "15assqyxax63hah0g51jd4d4za0kjyap9m2cgd1dim05pk7mgvfm";
    };

    phases = [ "installPhase" ];

    installPhase = ''
      mkdir -p $out/share/fonts/apple-emoji
      cp ${src} $out/share/fonts/apple-emoji/AppleColorEmoji.ttf
    '';

    meta = {
      homepage = "https://github.com/samuelngs/apple-emoji-linux";
      description = "Apple Color Emoji font";
      license = pkgs.lib.licenses.unfree;
    };
  };
in

{
  imports = [
  ];

  nixpkgs = {
    overlays = [
    ];
    config = {
      allowUnfree = true;
      # Workaround for https://github.com/nix-community/home-manager/issues/2942
      allowUnfreePredicate = _: true;
    };
  };


  home = {
    homeDirectory = "/home/r6t";
    stateVersion = "23.11";
    username = "r6t";
  };
  # Set dotfiles
  home.file.".config/hypr/hypridle.conf".source = ../dotfiles/hypr/hypridle.conf;
  home.file.".config/hypr/hyprland.conf".source = ../dotfiles/hypr/hyprland.conf;
  home.file.".config/hypr/hyprlock.conf".source = ../dotfiles/hypr/hyprlock.conf;
  home.file.".config/hypr/hyprpaper.conf".source = ../dotfiles/hypr/hyprpaper.conf;
  home.file.".config/waybar/config".source = ../dotfiles/waybar/config;
  home.file.".config/waybar/style.css".source = ../dotfiles/waybar/style.css;
  home.file.".local/share/rofi/themes/rounded-common.rasi".source = ../dotfiles/rofi/themes/rounded-common.rasi;
  home.file.".local/share/rofi/themes/rounded-purple-dark.rasi".source = ../dotfiles/rofi/themes/rounded-purple-dark.rasi;

  home.packages = with pkgs; [
    appleEmojiFont # see let block
    awscli2
    betaflight-configurator
    bitwarden
    brave
    brightnessctl # display brightness
    calibre # ebook manager
    dconf # hyprland support
    digikam # photo manager
    element-desktop # matrix client
    firefox-wayland
    freecad
    freerdp
    gnome.gnome-font-viewer
    grim # screenshots
    hypridle
    hyprlock
    hyprpaper # wallpaper
    hyprpicker # color picker
    kate # KDE text editor
    kdiff3 # KDE utility
    krename # KDE utility
    krusader # KDE file manager
    libsForQt5.breeze-gtk # KDE Breeze theme
    libsForQt5.breeze-icons # KDE app icons
    libsForQt5.elisa # KDE music player
    libsForQt5.gwenview # KDE image viewer
    libsForQt5.kio-extras # KDE support
    libsForQt5.polkit-kde-agent # KDE privlege escalation helper
    libsForQt5.qtwayland # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
    libsForQt5.qt5ct # KDE app support + https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
    libnotify # reqd for mako
    mako # notifications
    mellowplayer # music streaming
    obsidian # best notes app ever
    protonmail-bridge
    python3
    python311Packages.boto3
    python311Packages.pip
    python311Packages.troposphere
    python311Packages.jq
    python311Packages.yq
    librewolf
    pamixer # pulseaudio controls
    playerctl # media keys
    remmina
    rofi-calc
    rofi-emoji
    signal-desktop
    slurp # screenshots
    swaylock-effects # lock screen
    ungoogled-chromium
    virt-manager
    virt-viewer
    vlc
    webcord # Discord client
    xdg-utils # for opening default programs when clicking links
    waybar
    wl-clipboard # wl-copy and wl-paste for copy/paste from stdin / stdout
    wdisplays # wayland display config
    wlogout # wayland logout shortcuts
    wlr-randr # wayland
    youtube-dl
  ];
  programs.git = {
    enable = true;
    userName = "r6t";
    userEmail = "ryancast@gmail.com";
    extraConfig = {
      core = {
        editor = "nvim";
        init = { defaultBranch = "main"; };
        pull = { rebase = false; };
      };
    };
    ignores = [
      ".DS_Store"
      "*.pyc"
    ];
  };
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    plugins = with pkgs.vimPlugins; [
      rose-pine
    ];
    extraConfig = ''
      colorscheme rose-pine
      set number relativenumber
      set nowrap
      set nobackup
      set nowritebackup
      set noswapfile
    '';
    # extraLuaConfig goes to .config/nvim/init.lua, which cannot be managed as an individual file when using this
    extraLuaConfig = ''
    '';
    extraPackages = [
    ];
  };

  #programs.nixvim = {
  #    enable = true;
  #    colorschemes.onedark.enable = true;

  #    options = {
  #      shiftwidth = 2;
  #      number = true;
  #      relativenumber = true;
  #    };

  #    highlight = {
  #     Comment.fg = "#708090";
  #     Comment.bg = "none";
  #     Comment.bold = true;
  #    };

  #    plugins = {
  #        lualine = { enable = true; };
  #        nvim-tree = { enable = true; };
  #        luasnip = { enable = true; };
  #        cmp-buffer  = { enable = true; };
  #        cmp-emoji  = { enable = true; };
  #        cmp-nvim-lsp  = { enable = true; };
  #        cmp-path = { enable = true; };
  #    };

  #    plugins.lsp = {
  #      enable = true;

  #      servers = {
  #        nil_ls.enable = true;
  #        bashls.enable = true;

  #        lua-ls = {
  #          enable = true;
  #          settings.telemetry.enable = false;
  #        };

  #      };
  #    };

  #     plugins.nvim-cmp = {
  #       enable = true;
  #       autoEnableSources = true;
  #       snippet = { expand = "luasnip"; };

  #       sources = [
  #         { name = "nvim_lsp"; }
  #         { name = "luasnip"; }
  #         { name = "buffer"; }
  #         { name = "nvim_lua"; }
  #         { name = "path"; }
  #       ];

  #       mapping = {
  #         "<CR>" = "cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Insert, select = true })";
  #         "<Tab>" = {
  #           modes = [ "i" "s" ];
  #           action =
  #             # lua
  #             ''
  #               function(fallback)
  #                 if cmp.visible() then
  #                   cmp.select_next_item()
  #                 elseif require("luasnip").expand_or_jumpable() then
  #                   vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-expand-or-jump", true, true, true), "")
  #                 else
  #                   fallback()
  #                 end
  #               end
  #             '';
  #         };
  #         "<S-Tab>" = {
  #           modes = [ "i" "s" ];
  #           action =
  #             # lua
  #             ''
  #               function(fallback)
  #                 if cmp.visible() then
  #                   cmp.select_prev_item()
  #                 elseif require("luasnip").jumpable(-1) then
  #                   vim.fn.feedkeys(vim.api.nvim_replace_termcodes("<Plug>luasnip-jump-prev", true, true, true), "")
  #                 else
  #                   fallback()
  #                 end
  #               end
  #             '';
  #         };

  #       };
  #     };
  # };
  programs.alacritty = {
    enable = true;
    settings = {
    font = {
      size = 14.0;
    };
    selection = {
      save_to_clipboard = true;
    };
    };
  };
  programs.rofi = {
    cycle = true;
    enable = true;
    package = pkgs.rofi-wayland;
    plugins = [
      pkgs.rofi-calc
      pkgs.rofi-emoji
    ];
    theme = "/home/r6t/.local/share/rofi/themes/rounded-purple-dark.rasi";
  };
  programs.thunderbird = {
    enable = true;
    package = pkgs.thunderbird;
    profiles.r6t = {
      isDefault = true;
    };
  };
  programs.vscode = {
    enable = true;
    package = pkgs.vscodium;
    extensions = with pkgs.vscode-extensions; [
      bbenoist.nix
      continue.continue
      dracula-theme.theme-dracula
      ms-azuretools.vscode-docker
      ms-python.isort
      ms-python.python
      ms-python.vscode-pylance # unfree
      redhat.vscode-yaml
      vscodevim.vim
      yzhang.markdown-all-in-one
    ];
    userSettings = {
      "editor.fontFamily" = "Hack Nerd Font, Noto Color Emoji";
      "editor.fontSize" = 14;
      "window.titleBarStyle" = "custom";
      "merge-conflict.autoNavigateNextConflict.enabled" = true;
      "redhat.telemetry.enabled" = false;
    };
  };
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "aws" "git" "python" ];
      theme = "xiong-chiamiov-plus";
    };
    shellAliases = {
      "h" = "Hyprland";
      "gst" = "git status";
      "gd" = "git diff";
      "gds" = "git diff --staged";
    };
  };

  fonts = {
    fontconfig.enable = true;
  };

  home.sessionVariables = {
      MOZ_ENABLE_WAYLAND = 1;
      XDG_CURRENT_SESSION = "hyprland";
      XDG_SESSION_TYPE = "wayland";
      QT_QPA_PLATFORM="wayland"; # maybe "wayland-egl"
      QT_WAYLAND_DISABLE_WINDOWDECORATION = 1;
  };

  services.kdeconnect.enable = true; 
  services.kdeconnect.indicator = true; 

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
