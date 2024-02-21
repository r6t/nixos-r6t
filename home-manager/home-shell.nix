# This is your home-manager configuration file
# Use this to configure your home environment (it replaces ~/.config/nixpkgs/home.nix)
{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other home-manager modules here
  imports = [
    # If you want to use home-manager modules from other flakes (such as nix-colors):
    # inputs.nix-colors.homeManagerModule

    # You can also split up your configuration and import pieces of it here:
    # ./nvim.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
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
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "aws" "git" "python" "thefuck" ];
      theme = "xiong-chiamiov-plus";
    };
  };

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";
}
