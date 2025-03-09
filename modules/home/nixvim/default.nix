{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.nixvim.enable =
      lib.mkEnableOption "enable nixvim in home-manager";
  };

  config = lib.mkIf config.mine.home.nixvim.enable {
    home-manager.users.${userConfig.username}.programs.nixvim = {
      defaultEditor = true;
      enable = true;
      extraPlugins = with pkgs.vimPlugins; [
        oxocarbon-nvim
      ];
      globals.mapleader = " ";
      colorschemes.oxocarbon.enable = true;
      highlight.ExtraWhitespace.bg = "red";
      keymaps = [
        # codecompanion
        {
          mode = [ "n" "v" ];
          key = "<leader>aa";
          action = "<cmd>CodeCompanionActions<CR>";
          options = {
            desc = "CodeCompanion actions";
            silent = true;
          };
        }
        {
          mode = [ "n" "v" ];
          key = "<leader>ac";
          action = "<cmd>CodeCompanionChat Toggle<CR>";
          options = {
            desc = "Toggle CodeCompanion chat";
            silent = true;
          };
        }
        {
          mode = "v";
          key = "<leader>as";
          action = "<cmd>CodeCompanionChat Add<CR>";
          options = {
            desc = "Send selection to chat";
            silent = true;
          };
        }
        {
          mode = "n";
          key = "<leader>ai";
          action = "<cmd>CodeCompanion<CR>";
          options = {
            desc = "Inline assistant";
            silent = true;
          };
        }
        # oil
        {
          action = "<cmd>Oil<CR>";
          key = "<leader>-";
        }
        # telescope
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
        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            sources = [
              { name = "nvim_lsp"; }
              { name = "luasnip"; }
              { name = "buffer"; }
              { name = "path"; }
            ];
            mapping = {
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<Down>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<Up>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
              "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
              "<C-d>" = "cmp.mapping.scroll_docs(-4)";
              "<C-f>" = "cmp.mapping.scroll_docs(4)";
              "<C-Space>" = "cmp.mapping.complete()";
            };
          };
        };
        cmp-nvim-lsp.enable = true;
        cmp-buffer.enable = true;
        cmp-path.enable = true;
        codecompanion = {
          enable = true;
          settings = {
            adapters = {
              ollama = {
                __raw = ''
                  function()
                    return require('codecompanion.adapters').extend('ollama', {
                      env = {
                        url = "https://ollama.r6t.io",
                      },
                      parameters = {
                        temperature = 0.8,
                        top_k = 40,
                        top_p = 0.7,
                        repeat_penalty = 1.1,
                        num_ctx = 32768,
                        stream = true,
                      },
                      schema = {
                        model = {
                          default = "qwen2.5-coder:14b",
                        },
                      }
                    })
                  end
                '';
              };
            };
            opts = {
              log_level = "TRACE";
              send_code = true;
              use_default_actions = true;
              use_default_prompts = true;
              display = {
                action_palette = {
                  provider = "telescope";
                };
                completion = {
                  provider = "nvim-cmp";
                };
                command_palette = {
                  provider = "telescope";
                };
                chat = {
                  window = {
                    width = 0.4; # 40% of screen width
                    border = "rounded";
                  };
                };
              };
              actions = {
                auto_import = true;
                auto_format = true;
              };
            };
            strategies = {
              agent = {
                adapter = "ollama";
              };
              chat = {
                adapter = "ollama";
              };
              inline = {
                adapter = "ollama";
              };
            };
          };
        };
        conform-nvim = {
          enable = true;
          settings = {
            formatters_by_ft = {
              css = [ "prettier" ];
              html = [ "prettier" ];
              json = [ "prettier" ];
              lua = [ "stylua" ];
              markdown = [ "prettier" ];
              nix = [ "alejandra" ];
              python = [ "black" ];
              ruby = [ "rubyfmt" ];
              terraform = [ "tofu_fmt" ];
              tf = [ "tofu_fmt" ];
              yaml = [ "yamlfmt" ];
            };
          };
        };
        dressing.enable = true;
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
