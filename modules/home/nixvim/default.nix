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
      "OPENROUTER_API_KEY" = {
        owner = userConfig.username;
      };
    };

    home-manager.users.${userConfig.username} = {
      home = {
        file = {
          ".config/fish/conf.d/90-vim-sops-secrets.fish" = {
            text = builtins.readFile ./setVimSessionVars.fish;
            executable = true;
          };
        };
        packages = with pkgs; [
          # formatters
          python3Packages.black
          python3Packages.isort
          nodePackages.prettier
          # linters
          alejandra
          deadnix
          nixpkgs-fmt
          stylua
          statix
          yamlfmt
          # media
          viu
          chafa
          # tools
          lsof
          opencode
          tree-sitter
        ];
      };

      programs.nixvim = {
        defaultEditor = true;
        enable = true;
        extraPlugins = with pkgs.vimPlugins; [
          direnv-vim
          opencode-nvim
          oxocarbon-nvim
          snacks-nvim
          zellij-nvim
          nvim-lspconfig
        ];

        extraConfigLua = ''
          -- Configure opencode.nvim
          vim.g.opencode_opts = {
            -- Enable auto-reload of buffers when opencode makes changes
            auto_reload = true,

            -- DO NOT auto-register cmp sources - causes ipairs error with nixvim
            auto_register_cmp_sources = false,

            -- Define custom prompts (optional)
            prompts = {
              explain = { prompt = "Explain @this and its context" },
              optimize = { prompt = "Optimize @this for performance and readability" },
              document = { prompt = "Add comments documenting @this" },
              test = { prompt = "Add tests for @this" },
              review = { prompt = "Review @this for correctness and readability" },
              fix = { prompt = "Fix @diagnostics" },
            },
          }

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

          # Fugitive
          {
            action = "<cmd>Git<CR>";
            key = "<leader>gg";
            options.desc = "Git status";
          }
          {
            action = "<cmd>Git blame<CR>";
            key = "<leader>gb";
            options.desc = "Git blame";
          }

          # LSP
          {
            action = "<cmd>LspInfo<CR>";
            key = "<leader>li";
            options.desc = "LSP Info";
          }
          {
            action = "<cmd>lua vim.lsp.buf.definition()<CR>";
            key = "<leader>ld";
            options.desc = "LSP Go to definition";
          }
          {
            action = "<cmd>lua vim.lsp.buf.references()<CR>";
            key = "<leader>lr";
            options.desc = "LSP Find references";
          }
          {
            action = "<cmd>lua vim.lsp.buf.rename()<CR>";
            key = "<leader>ln";
            options.desc = "LSP Rename symbol";
          }
          {
            action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
            key = "<leader>la";
            mode = [ "n" "x" ];
            options.desc = "LSP Code actions";
          }
          {
            action = "<cmd>lua vim.diagnostic.setqflist()<CR>";
            key = "<leader>le";
            options.desc = "Show all diagnostics";
          }
          {
            action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
            key = "<leader>en";
            options.desc = "Next diagnostic";
          }
          {
            action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
            key = "<leader>ep";
            options.desc = "Previous diagnostic";
          }

          # File navigation
          {
            action = "<cmd>Oil<CR>";
            key = "<leader>-";
            options.desc = "File navigation";
          }

          # OpenCode
          {
            action = "<cmd>lua require('opencode').ask('@this: ', { submit = true })<CR>";
            key = "<leader>oa";
            mode = [ "n" "x" ];
            options.desc = "Ask OpenCode about this";
          }
          {
            action = "<cmd>lua require('opencode').select()<CR>";
            key = "<leader>os";
            mode = [ "n" "x" ];
            options.desc = "Select OpenCode prompt";
          }
          {
            action = "<cmd>lua require('opencode').prompt('@this')<CR>";
            key = "<leader>o+";
            mode = [ "n" "x" ];
            options.desc = "Add this to OpenCode context";
          }
          {
            action = "<cmd>lua require('opencode').toggle()<CR>";
            key = "<leader>ot";
            options.desc = "Toggle embedded OpenCode";
          }
          {
            action = "<cmd>lua require('opencode').command()<CR>";
            key = "<leader>oc";
            options.desc = "Select OpenCode command";
          }
          {
            action = "<cmd>lua require('opencode').command('session_new')<CR>";
            key = "<leader>on";
            options.desc = "New OpenCode session";
          }
          {
            action = "<cmd>lua require('opencode').command('session_interrupt')<CR>";
            key = "<leader>oi";
            options.desc = "Interrupt OpenCode session";
          }

          # Snacks Picker (f for find)
          {
            action = "<cmd>lua Snacks.picker.files()<CR>";
            key = "<leader>ff";
            options.desc = "Find files";
          }
          {
            action = "<cmd>lua Snacks.picker.recent()<CR>";
            key = "<leader>fr";
            options.desc = "Find recent files";
          }
          {
            action = "<cmd>lua Snacks.picker.grep()<CR>";
            key = "<leader>fg";
            options.desc = "Live grep";
          }
          {
            action = "<cmd>lua Snacks.picker.buffers()<CR>";
            key = "<leader>fb";
            options.desc = "Find buffers";
          }
          {
            action = "<cmd>lua Snacks.picker.grep_buffers()<CR>";
            key = "<leader>fB";
            options.desc = "Grep open buffers";
          }
          {
            action = "<cmd>lua Snacks.picker.help()<CR>";
            key = "<leader>fh";
            options.desc = "Help tags";
          }
          {
            action = "<cmd>lua Snacks.picker.git_files()<CR>";
            key = "<leader>fp";
            options.desc = "Git files aka find in project";
          }
          {
            action = "<cmd>lua Snacks.picker.lsp_symbols()<CR>";
            key = "<leader>ls";
            options.desc = "LSP symbols";
          }
        ];

        opts = {
          autoread = true;
          ignorecase = true;
          inccommand = "split";
          incsearch = true;
          number = true;
          relativenumber = true;
          shiftwidth = 2;
          signcolumn = "yes:1";
          smartcase = true;
          swapfile = false;
          undofile = true;
          updatetime = 100;
        };

        plugins = {
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
                # Add opencode sources to default list
                default = [
                  "lsp"
                  "buffer"
                  "path"
                  "snippets"
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
                python = [ "isort" "black" ];
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
              html.enable = true;
              cssls.enable = true;
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
              yamlls.enable = true;
            };
          };

          snacks = {
            enable = true;
            settings = {
              input = {
                enabled = true;
              };
              picker = {
                enabled = true;
                layout = "telescope";
              };
              terminal = {
                enabled = true;
              };
            };
          };

          oil.enable = true;
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

