{ config, pkgs, ... }:

{
  home-manager.users.r6t = { pkgs, ...}: {
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
    home.homeDirectory = "/home/r6t";
    home.username = "r6t";
    home.stateVersion = "23.11";
  };
}