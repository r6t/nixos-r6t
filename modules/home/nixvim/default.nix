{ lib, config, pkgs, ... }: { 

    options = {
      mine.home.nixvim.enable =
        lib.mkEnableOption "enable nixvim in home-manager";
    };

    config = lib.mkIf config.mine.home.nixvim.enable { 
      home-manager.users.r6t.programs.nixvim = {
        autoCmd = [
          {
            event = "FileType";
            pattern = "nix";
            command = "setlocal tabstop=2 shiftwidth=2";
          }
        ];
        defaultEditor = true;
        enable = true;
        extraPlugins = [ pkgs.vimPlugins.oxocarbon-nvim ];
				globals.mapleader = " ";
        colorschemes.oxocarbon.enable = true;
      	highlight.ExtraWhitespace.bg = "red";
				keymaps = [
          {
            action = "<cmd>Oil<CR>";
            key = "<leader>-";
          }
        ];
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
      	  conform-nvim = {
            enable = true;
      	  	formattersByFt = {
      	    	css = ["prettier"];
              html = ["prettier"];
              json = ["prettier"];
      	    	lua = ["stylua"];
              markdown = ["prettier"];
              nix = ["alejandra"];
      	      python = [ "black" ];
              ruby = ["rubyfmt"];
              terraform = ["tofu_fmt"];
              tf = ["tofu_fmt"];
              yaml = ["yamlfmt"];
      	    };
          };
      	  cmp = {
      	    enable = true;
      	    autoEnableSources = true;
      	  };
      	  lualine.enable = true;
      	  luasnip.enable = true;
      	  lsp = {
            enable = true;
      	    servers = {
      	      jsonls.enable = true;
      	      lua-ls.enable = true;
      	      marksman.enable = true;
      	      nixd.enable = true;
      	      pylsp = {
      	        enable = true;
      	        settings.plugins = {
      	          black.enabled = true;
      	          flake8.enabled = false;
      	          isort.enabled = true;
      	          jedi.enabled = false;
      	          mccabe.enabled = false;
      	          pycodestyle.enabled = false;
      	          pydocstyle.enabled = true;
      	          pyflakes.enabled = false;
      	          pylint.enabled = true;
      	          rope.enabled = false;
      	          yapf.enabled = false;
      	        };
      	      };
      	      yamlls.enable = true;
      	    };
      	  };
      	  none-ls.sources.formatting.black.enable = true;
      	  oil.enable = true;
      	  ollama = {
      	    enable = true;
      	    model = "mistral";
      	    url = "http://silvertorch.magic.internal:11434";
      	  };
      	  telescope.enable = true;
      	  treesitter.enable = true;
      	};
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
    };
  };
}
