# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, lib, pkgs, ... }:

{
  imports =
    [ <home-manager/nixos>
      # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  nixpkgs.config.allowUnfree = true;

  networking.hostName = "nix-pxg"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  services.qemuGuest.enable = true;

  services.xrdp.enable = true;
  services.xrdp.defaultWindowManager= "startplasma-x11";
  services.xrdp.openFirewall = true;
  
  programs.zsh.enable = true;
  services.flatpak.enable = true;

  # Docker
  virtualisation.docker.enable = true;
  virtualisation.docker.enableOnBoot = true;
  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  ### USER + APPLICATIONS
  # Probably should be managing the user itself via home-manager?
  users.users.r6t = { isNormalUser = true; description = "user"; extraGroups = [ "docker" "networkmanager" "wheel" ]; shell = pkgs.zsh;
  };

  home-manager.users.r6t = { pkgs, ...}: {
    home.file.".config/nixpkgs/config.nix".text = ''
    {
    	allowUnfree = true;
    }
    '';
    home.file.".config/nvim/after/plugin/fugitive.lua".text = ''
      vim.keymap.set("n", "<leader>gs", vim.cmd.Git)
    '';
    home.file.".config/nvim/after/plugin/harpoon.lua".text = ''
      local mark = require("harpoon.mark")
      local ui = require("harpoon.ui")
      
      vim.keymap.set("n", "<leader>a", mark.add_file)
      vim.keymap.set("n", "<C-e>", ui.toggle_quick_menu)
      
      vim.keymap.set("n", "<C-h>", function() ui.nav_file(1) end)
      vim.keymap.set("n", "<C-t>", function() ui.nav_file(2) end)
      vim.keymap.set("n", "<C-n>", function() ui.nav_file(3) end)
      vim.keymap.set("n", "<C-s>", function() ui.nav_file(4) end)
    '';
    home.file.".config/nvim/after/plugin/lsp.lua".text = ''
      local lsp = require('lsp-zero').preset({})

      lsp.on_attach(function(client, bufnr)
        -- see :help lsp-zero-keybindings
        -- to learn the available actions
        lsp.default_keymaps({buffer = bufnr})
      end)
      
      lsp.setup()
    '';
    home.file.".config/nvim/after/plugin/telescope.lua".text = ''
      local builtin = require('telescope.builtin')
      vim.keymap.set('n', '<leader>pf', builtin.find_files, {})
      vim.keymap.set('n', 'C-p', builtin.git_files, {})
      vim.keymap.set('n', '<leader>ps', function()
        builtin.grep_string({ search = vim.fn.input("Grep > ") });
      end)
    '';
    home.file.".config/nvim/after/plugin/undotree.lua".text = ''
      vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle)
    '';
    home.file.".config/nvim/lua/r6t/init.lua".text = ''
    '';
    home.file.".config/nvim/lua/r6t/remap.lua".text = ''
      vim.g.mapleader = " "
      vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)
    '';
    home.packages = with pkgs; [
      ansible
      awscli2
      brave
      firefox
      freecad
      freetube
      freerdp
      gh
      kate
      krusader
      mullvad-vpn
      neofetch
      librewolf
      ripgrep
      remmina
      signal-desktop
      # slack
      thefuck
      tmux
      ungoogled-chromium
      virt-manager
      vlc
      youtube-dl
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
        cmp-buffer
        cmp-nvim-lsp
        cmp-nvim-lua
        cmp-path
	cmp_luasnip
	friendly-snippets
        harpoon
        indentLine
	# mini-nvim
	nvim-lspconfig # lsp-zero
        lsp-zero-nvim
        luasnip
	nvim-cmp
	nvim-treesitter.withAllGrammars
	nvim-treesitter-context
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
      extraPackages = [
        pkgs.nodePackages.bash-language-server
	pkgs.nodePackages.pyright
        pkgs.nodePackages.vim-language-server
        pkgs.nodePackages.yaml-language-server
      ];
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
    home.homeDirectory = "/home/r6t";
    home.sessionVariables = {
    };
    home.username = "r6t";
    home.stateVersion = "23.05";
  };

  # List packages installed in system profile. To search, run: $ nix search wget
  environment.systemPackages = with pkgs; [
      curl
      htop
      jq
      libgccjit
      python311
      #python311Packages.pip
      #python311Packages.slack-sdk
      pypy3
      tree
      unzip
      wget
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?

}
