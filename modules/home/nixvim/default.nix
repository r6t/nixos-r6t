{ lib, config, pkgs, userConfig, ... }: { 

    imports = [
      ./codecompanion.nix
    ];

    options = {
      mine.home.nixvim.enable =
        lib.mkEnableOption "enable nixvim in home-manager";
    };

    config = lib.mkIf config.mine.home.nixvim.enable { 
      home-manager.users.${userConfig.username}.programs.nixvim = {
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
          {
            action = "<cmd>Telescope find_files<CR>";
            key = "<leader>ff";
          }
          {
            action = "<cmd>Telescope live_grep<CR>";
            key = "<leader>fg";
          }
          {
            action = "<cmd>Telescope buffers<CR>";
            key = "<leader>fb";
          }
          {
            action = "<cmd>Telescope help_tags<CR>";
            key = "<leader>fh";
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
	    settings = {
      	      formatters_by_ft = {
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
          };
      	  cmp = {
      	    enable = true;
      	    autoEnableSources = true;
      	  };
	  fugitive.enable = true;
	  git-conflict.enable = true;
      	  lualine.enable = true;
      	  luasnip.enable = true;
      	  lsp = {
            enable = true;
      	    servers = {
	      bashls.enable = true;
      	      jsonls.enable = true;
	      lua_ls = {
                enable = true;
                settings.telemetry.enable = false;
              };
      	      marksman.enable = true;
	      nil_ls = {
                enable = true;
                settings = {
                  formatting.command = [ "nixpkgs-fmt" ];
                };
              };
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
      	  treesitter = {
	  enable = true;
		folding = false;
		settings.indent.enable = true;
	};
	web-devicons.enable = true;
	which-key = {
	  enable = true;
	  settings.preset = "helix";
	  };
      	};
        viAlias = true;
        vimAlias = true;
        vimdiffAlias = true;
    };
  };
}
