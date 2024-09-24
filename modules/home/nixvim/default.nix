{ lib, config, inputs, pkgs, ... }: { 

    options = {
      mine.home.nixvim.enable =
        lib.mkEnableOption "enable nixvim in home-manager";
    };

    config = lib.mkIf config.mine.home.nixvim.enable { 
      home-manager.users.r6t.programs.nixvim = {
        defaultEditor = true;
        enable = true;
        extraPlugins = [ pkgs.vimPlugins.oxocarbon-nvim ];
        colorschemes.oxocarbon.enable = true;
        opts = {
	  updatetime = 100;
	  number = true;
	  relativenumber = true;
	  shiftwidth = 2;
	  swapfile = false;
	  undofile = true;
	  incsearch = true;
	  inccommand = "split";
	  ignorecase = true;
	  smartcase = true;
          signcolumn = "yes:1";
	};
	plugins = {
	  cmp = {
	    enable = true;
	    autoEnableSources = true;
	  };
	  lualine.enable = true;
	  luasnip.enable = true;
	  lsp = {
            enable = true;
	    servers = {
	      pyright.enable = true; # python
	      lua-ls.enable = true;
	    };
	  };
	  oil.enable = true;
	  telescope.enable = true;
	  treesitter.enable = true;
	};
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
    };
  };
}
