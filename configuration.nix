# r6t's nixos configuration
# Currently used to manage a single Framework laptop

{ config, pkgs, ... }:

{ imports =
    [ <home-manager/nixos>
      <nixos-hardware/framework>

      # Include the results of the hardware scan.
      ./hardware-configuration.nix ];

  ### NIXOS CONFIGURATION
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.initrd.secrets = { "/crypto_keyfile.bin" = null;
  };
  boot.initrd.luks.devices."luks-f26077b3-1094-45f1-8c6e-07f7fee52e72".device = "/dev/disk/by-uuid/f26077b3-1094-45f1-8c6e-07f7fee52e72"; 
  boot.initrd.luks.devices."luks-f26077b3-1094-45f1-8c6e-07f7fee52e72".keyFile = "/crypto_keyfile.bin";

  environment.shells = with pkgs; [ zsh ]; # /etc/shells

  hardware.bluetooth.enable = true;
  hardware.pulseaudio.enable = false; # disabled for pipewire

  networking.networkmanager.enable = true;
  networking.hostName = "mountainball";
  # networking.wireless.enable = true; # wpa_supplicant

  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = { LC_ADDRESS = "en_US.UTF-8"; LC_IDENTIFICATION = "en_US.UTF-8"; LC_MEASUREMENT = "en_US.UTF-8"; LC_MONETARY = 
    "en_US.UTF-8"; LC_NAME = "en_US.UTF-8"; LC_NUMERIC = "en_US.UTF-8"; LC_PAPER = "en_US.UTF-8"; LC_TELEPHONE = "en_US.UTF-8"; LC_TIME = 
    "en_US.UTF-8";
  };

  nix = {
    # NixOS garbage collection
    gc = {
      automatic = true;
      dates = "monthly";
      options = "--delete-older-than-60d";
    };
    settings = {
      auto-optimise-store = true;
    };
  };

  programs.hyprland.enable = false;
  programs.zsh.enable = true;

  sound.enable = true; # see services.pipewire

  security.rtkit.enable = true;

  time.timeZone = "America/Los_Angeles";

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-wlr pkgs.xdg-desktop-portal-gtk ];

  ### USER + APPLICATIONS
  # Probably should be managing the user itself via home-manager?
  users.users.user = { isNormalUser = true; description = "user"; extraGroups = [ "networkmanager" "wheel" ]; shell = pkgs.zsh;
  };

  home-manager.users.user = { pkgs, ...}: {
    home.file.".config/electron13-flags.conf".text = ''
      --enable-features=UseOzonePlatform
      --ozone-platform=wayland
    '';
#    home.file.".config/nvim/after/plugin/colors.lua".text = ''
#      funtion ColorMyPencils(color)
#        color = color or "rose-pine"
#	vim.cmd.colorscheme(color)
#
#	vim.api.neovim_set_hl(0, "Normal", { bg = "none" })
#	vim.api.neovim_set_hl(0, "NormalFloat", { bg = "none" })
#      end
#
#      ColorMyPencils()
#    '';
    home.file.".config/nvim/after/plugin/telescope.lua".text = ''
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
      vim.keymap.set('n', 'C-p', builtin.git_files, {})
      vim.keymap.set('n', '<leader>ps', function()
        builtin.grep_string({ search = vim.fn.input("Grep > ") });
      end)
    '';
#    home.file.".config/nvim/after/plugin/treesitter.lua".text = ''
#      require'nvim-treesitter.configs'.setup {
#        -- A list of parser names, or "all" (the five listed parsers should always be installed)
#        ensure_installed = { "c", "lua", "vim", "vimdoc", "query" },
#      
#        -- Install parsers synchronously (only applied to `ensure_installed`)
#        sync_install = false,
#      
#        -- Automatically install missing parsers when entering buffer
#        -- Recommendation: set to false if you don't have `tree-sitter` CLI installed locally
#        auto_install = false,
#      
#        highlight = {
#          enable = true,
#      
#          -- Setting this to true will run `:h syntax` and tree-sitter at the same time.
#          -- Set this to `true` if you depend on 'syntax' being enabled (like for indentation).
#          -- Using this option may slow down your editor, and you may see some duplicate highlights.
#          -- Instead of true it can also be a list of languages
#          additional_vim_regex_highlighting = false,
#        },
#      } 
#    '';
    home.file.".config/nvim/lua/r6t/init.lua".text = ''
      print("hello from r6t via nix")
    '';
    home.file.".config/nvim/lua/r6t/remap.lua".text = ''
      vim.g.mapleader = " "
      vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
    '';
    home.packages = [
      pkgs.ansible
      pkgs.betaflight-configurator
      pkgs.brave
      pkgs.firefox-wayland
      pkgs.freecad
      pkgs.freetube
      pkgs.freerdp
      pkgs.kate
      pkgs.krusader
      pkgs.mullvad-vpn
      pkgs.neofetch
      pkgs.librewolf
      pkgs.ripgrep
      pkgs.remmina
      pkgs.signal-desktop
      pkgs.thefuck
      pkgs.tmux
      pkgs.ungoogled-chromium
      pkgs.virt-manager
      pkgs.vlc
      pkgs.webcamoid
      pkgs.youtube-dl

    ];
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
    programs.git = {
      enable = true;
      userName = "r6t";
      userEmail = "ryancast@gmail.com";
      extraConfig = {
        core = {
          editor = "nvim";
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
        harpoon
	mini-nvim
	nvim-lspconfig
	nvim-treesitter.withAllGrammars
	nvim-treesitter-context
	playground
	plenary-nvim
	rose-pine
	telescope-nvim
	undotree
	vim-fugitive
      ];
      extraConfig = ''
        colorscheme rose-pine
        set number relativenumber
      '';
      extraLuaConfig = ''
        require("r6t")
        require("r6t.remap")
      '';
    };
    programs.vscode = {
      enable = true;
      package = pkgs.vscodium;
      extensions = with pkgs.vscode-extensions; [
        dracula-theme.theme-dracula
        vscodevim.vim
        yzhang.markdown-all-in-one
      ];
    };
    programs.zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
	plugins = [ "aws" "git" "python" "thefuck" ];
        theme = "xiong-chiamiov-plus";
      };
    };
    home.homeDirectory = "/home/user";
    home.sessionVariables = {
        MOZ_ENABLE_WAYLAND = 1;
    };
    home.username = "user";
    home.stateVersion = "23.05";
  };

  # List packages installed in system profile. To search, run: $ nix search wget
  environment.systemPackages = with pkgs; [
      curl
      htop
      jq
      libgccjit
      tree
      unzip
      wget
  ];

  # Some programs need SUID wrappers, can be configured further or are started in user sessions. programs.mtr.enable = true; programs.gnupg.agent = {
  #   enable = true; enableSSHSupport = true;
  # };

  ### SERVICES:
  services.flatpak.enable = true;
  services.fprintd.enable = true;
  services.fwupd.enable = true; # Linux firmware updater
  services.mullvad-vpn.enable = true; # Mullvad desktop app
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default, no need to redefine it in your config for now)
    #media-session.enable = true;
  };
  services.printing.enable = true; # CUPS print support
  services.syncthing = {
    enable = true;
    dataDir = "/home/user/icloud";
    openDefaultPorts = true;
    configDir = "/home/user/.config/syncthing";
    user = "user";
    group = "users";
    guiAddress = "0.0.0.0:8384";
  };
  services.xserver.enable = true;
  services.xserver = { layout = "us"; xkbVariant = ""; }; # X11 keymap
  services.xserver.displayManager.sddm.enable = true; # KDE Plasma
  services.xserver.desktopManager.plasma5.enable = true; # KDE Plasma
  services.xserver.displayManager.defaultSession = "plasmawayland"; # KDE Plasma
  # services.xserver.libinput.enable = true; # Enable touchpad support (enabled default in most desktopManager).

  # Enable the OpenSSH daemon. services.openssh.enable = true;

  # Open ports in the firewall. networking.firewall.allowedTCPPorts = [ ... ]; networking.firewall.allowedUDPPorts = [ ... ]; Or disable the firewall 
  # altogether. networking.firewall.enable = false;

  # Before changing this value read the documentation for this option (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05";

}
