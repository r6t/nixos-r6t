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
    };

    home-manager.users.${userConfig.username} = {
      home = {
        file.".config/fish/conf.d/90-vim-sops-secrets.fish" = {
          text = builtins.readFile ./setVimSessionVars.fish;
          executable = true;
        };
        packages = with pkgs; [
          # linters
          alejandra
          deadnix
          nixpkgs-fmt
          rubyfmt
          stylua
          statix
          yamlfmt
          # media
          viu
          chafa
          # tools
          tree-sitter
        ];
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
          -- Set default provider on startup (avoids vertex default)
          vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
              vim.defer_fn(function()
                -- Switch to qwen-coder as default
                vim.cmd("AvanteSwitchProvider qwen-coder")
                -- Visual confirmation
                vim.notify("Avante: Default provider set to Qwen 2.5 Coder 7B @ ollama", vim.log.levels.INFO, {
                  title = "Avante.nvim",
                  timeout = 2000,
                })
              end, 500)
            end,
          })

          -- Provider switching function with visual feedback
          local function switch_provider_with_feedback(provider, display_name)
            return function()
              vim.cmd("AvanteSwitchProvider " .. provider)
              vim.notify("Switched to: " .. display_name, vim.log.levels.INFO, {
                title = "Avante Provider",
                timeout = 1500,
              })
            end
          end

          -- Create provider switching commands with feedback
          vim.api.nvim_create_user_command("AvanteQwen7B", 
            switch_provider_with_feedback("qwen-coder", "Qwen 2.5 Coder 7B on ollama"), {})
          vim.api.nvim_create_user_command("AvanteQwen14B", 
            switch_provider_with_feedback("qwen-coder-14b", "Qwen 2.5 Coder 14B on ollama"), {})
          vim.api.nvim_create_user_command("AvanteDeepSeek", 
            switch_provider_with_feedback("deepseek-r1-14b", "DeepSeek R1 14B on ollama"), {})
          vim.api.nvim_create_user_command("AvanteClaude", 
            switch_provider_with_feedback("bedrock-claude", "Claude Sonnet 4 on AWS Bedrock"), {})

          -- Configure blink-cmp formatting with lspkind
          require('blink.cmp').setup({
            appearance = {
              use_nvim_cmp_as_default = true,
            },
            completion = {
              formatting = {
                format = require("lspkind").cmp_format({
                  mode = "symbol_text",
                  maxwidth = 50,
                  ellipsis_char = "...",
                }),
              },
            },
          })

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
          # Buffer navigation
          {
            action = "<cmd>bnext<CR>";
            key = "<leader>bn";
            options.desc = "Next buffer";
          }
          {
            action = "<cmd>bprevious<CR>";
            key = "<leader>bp";
            options.desc = "Previous buffer";
          }

          # LSP
          {
            action = "<cmd>LspInfo<CR>";
            key = "<leader>li";
            options.desc = "LSP Info";
          }
          {
            action = "<cmd>lua vim.lsp.buf.definition()<CR>";
            key = "gd";
            options.desc = "Go to definition";
          }
          {
            action = "<cmd>lua vim.lsp.buf.references()<CR>";
            key = "gr";
            options.desc = "Find references";
          }

          # File navigation
          {
            action = "<cmd>Oil<CR>";
            key = "<leader>-";
            options.desc = "Open Oil file manager";
          }

          # Telescope
          {
            action = "<cmd>Telescope find_files<CR>";
            key = "<leader>ff";
            options.desc = "Find files";
          }
          {
            action = "<cmd>Telescope live_grep<CR>";
            key = "<leader>fg";
            options.desc = "Live grep";
          }
          {
            action = "<cmd>Telescope buffers<CR>";
            key = "<leader>fb";
            options.desc = "Find buffers";
          }
          {
            action = "<cmd>Telescope help_tags<CR>";
            key = "<leader>fh";
            options.desc = "Help tags";
          }

          # Avante Provider Switching with Visual Feedback
          {
            action = "<cmd>AvanteQwen7B<CR>";
            key = "<leader>a1";
            options.desc = "Switch to Qwen 2.5 Coder 7B @ ollama";
          }
          {
            action = "<cmd>AvanteQwen14B<CR>";
            key = "<leader>a2";
            options.desc = "Switch to Qwen 2.5 Coder 14B @ ollama";
          }
          {
            action = "<cmd>AvanteDeepSeek<CR>";
            key = "<leader>a3";
            options.desc = "Switch to DeepSeek R1 14B @ ollama";
          }
          {
            action = "<cmd>AvanteClaude<CR>";
            key = "<leader>a4";
            options.desc = "Switch to Claude Sonnet 4 @ AWS Bedrock";
          }

          # Avante core functions
          {
            action = "<cmd>AvanteAsk<CR>";
            key = "<leader>aa";
            options.desc = "Ask Avante";
          }
          {
            action = "<cmd>AvanteToggle<CR>";
            key = "<leader>at";
            options.desc = "Toggle Avante sidebar";
          }
          {
            action = "<cmd>AvanteEdit<CR>";
            key = "<leader>ae";
            options.desc = "Edit with Avante";
            mode = [ "n" "v" ];
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
              provider = "qwen-coder"; # Default provider - qwen 7b

              providers = {
                qwen-coder = {
                  __inherited_from = "ollama";
                  endpoint = "https://ollama.r6t.io";
                  model = "qwen2.5-coder:7b";
                  extra_request_body = {
                    options = {
                      temperature = 0.7;
                      keep_alive = "5m";
                    };
                  };
                };
                qwen-coder-14b = {
                  __inherited_from = "ollama";
                  endpoint = "https://ollama.r6t.io";
                  model = "qwen2.5-coder:14b";
                  extra_request_body = {
                    options = {
                      temperature = 0.7;
                      keep_alive = "5m";
                    };
                  };
                };
                deepseek-r1-14b = {
                  __inherited_from = "ollama";
                  endpoint = "https://ollama.r6t.io";
                  model = "deepseek-r1:14b";
                  extra_request_body = {
                    options = {
                      temperature = 0.7;
                      keep_alive = "5m";
                    };
                  };
                };
                bedrock-claude = {
                  __inherited_from = "bedrock";
                  model = "anthropic.claude-sonnet-4-20250514-v1:0";
                  extra_request_body = { };
                };
              };

              behaviour = {
                auto_suggestions = false;
                support_paste_from_clipboard = true;
                enable_cursor_planning_mode = true;
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
                    semantic_token_resolution.enabled = false;
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

          lspkind = {
            enable = true;
            # not blink-cmp
            cmp.enable = false;
          };
          dressing.enable = true;
          fugitive.enable = true;
          fzf-lua.enable = true;
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

