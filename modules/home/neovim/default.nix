{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.neovim.enable =
        lib.mkEnableOption "enable neovim in home-manager";
    };

    config = lib.mkIf config.mine.home.neovim.enable { 
      home-manager.users.r6t.programs.neovim = {
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
    };
}