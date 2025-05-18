{ lib, config, pkgs, userConfig, ... }: {

  options = {
    mine.home.nixvim.enable =
      lib.mkEnableOption "enable nixvim in home-manager";
  };

  config = lib.mkIf config.mine.home.nixvim.enable {
    sops.secrets = {
      "BEDROCK_KEYS" = {
        owner = userConfig.username;
      };
      "GH_TOKEN" = {
        owner = userConfig.username;
      };
    };

    home-manager.users.${userConfig.username} = {
      home.file.".config/fish/conf.d/90-vim-sops-secrets.fish" = {
        text = builtins.readFile ./setVimSessionVars.fish;
        executable = true;
      };

      programs.nixvim = {
        defaultEditor = true;
        enable = true;
        extraPlugins = with pkgs.vimPlugins; [
          blink-cmp-avante
          direnv-vim
          oxocarbon-nvim
          zellij-nvim
          nvim-lspconfig
        ];

        extraConfigLua = ''
                  if vim.lsp.config then
                    vim.lsp.config('*', {
                      capabilities = require('blink.cmp').get_lsp_capabilities(),
                    })
                  end

                  -- Fix for zellij.nvim health check
                  vim.health = vim.health or {}
                  vim.health.report_start = vim.health.report_start or function() end
                  vim.health.report_ok = vim.health.report_ok or function() end
                  vim.health.report_warn = vim.health.report_warn or function() end
                  vim.health.report_error = vim.health.report_error or function() end
          	vim.health.report_info = vim.health.report_info or function() end
        '';

        globals = {
          mapleader = " ";
          direnv_auto = 1;
          direnv_silent_load = 0;
        };
        colorschemes.oxocarbon.enable = true;
        highlight.ExtraWhitespace.bg = "red";
        keymaps = [
          # lsp
          {
            action = "<cmd>LspInfo<CR>";
            key = "<leader>li";
            options.desc = "LSP Info";
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
          avante = {
            enable = true;
            settings = {
              provider = "ollama";
              behaviour = {
                enable_cursor_planning_mode = true;
              };
              ollama = {
                endpoint = "https://ollama.r6t.io";
                model = "llama3.1:latest";
              };
              selector = {
                provider = "fzf_lua";
                provider_opts = { };
              };
            };
          };
          blink-cmp = {
            enable = true;
            setupLspCapabilities = true;
            settings = {
              appearance = {
                nerd_font_variant = "normal";
                use_nvim_cmp_as_default = true;
              };
              cmdline = {
                enabled = true;
                keymap = { preset = "inherit"; };
                completion = {
                  list.selection.preselect = false;
                  menu = { auto_show = true; };
                  ghost_text = { enabled = true; };
                };
              };
              completion = {
                menu.border = "rounded";
                accept = {
                  auto_brackets = {
                    enabled = true;
                    semantic_token_resolution = {
                      enabled = false;
                    };
                  };
                };
                documentation = {
                  auto_show = true;
                  window.border = "rounded";
                };
              };
              sources = {
                default = [
                  "lsp"
                  "buffer"
                  "path"
                  "snippets"
                  "git"
                  "avante_commands"
                  "avante_mentions"
                  "avante_files"
                ];
                providers = {
                  buffer = {
                    enabled = true;
                    score_offset = 0;
                  };
                  lsp = {
                    name = "LSP";
                    enabled = true;
                    score_offset = 10;
                  };
                  git = {
                    module = "blink-cmp-git";
                    name = "Git";
                  };
                  avante_commands = {
                    name = "avante_commands";
                    module = "blink.compat.source";
                  };
                  avante_mentions = {
                    name = "avante_mentions";
                    module = "blink.compat.source";
                  };
                  avante_files = {
                    name = "avante_files";
                    module = "blink.compat.source";
                  };
                };
              };
            };
          };
          blink-cmp-git.enable = true;
          blink-compat.enable = true;
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
                yaml = [ "yamlfmt" ];
              };
            };
          };
          lspkind.enable = true;
          dressing.enable = true;
          fugitive.enable = true;
          fzf-lua.enable = true;
          git-conflict.enable = true;
          lualine.enable = true;
          luasnip.enable = false;
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
              pyright = {
                enable = true;
                settings = {
                  python = {
                    analysis = {
                      typeCheckingMode = "basic";
                      autoSearchPaths = true;
                      useLibraryCodeForTypes = true;
                      diagnosticMode = "workspace";
                    };
                  };
                };
              };
              pylsp = {
                enable = false;
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
  };
}
