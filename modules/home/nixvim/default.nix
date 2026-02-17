{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.nixvim;

  # Shared packages
  nixvimPackages = with pkgs; [
    # formatters
    python3Packages.black
    python3Packages.isort
    nodePackages.prettier
    shfmt
    go # provides gofmt and goimports
    rustfmt
    # linters
    alejandra
    deadnix
    nixpkgs-fmt
    python3Packages.pylint
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

  # Shared nixvim configuration
  nixvimConfig = {
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

        -- Auto-reload files when changed externally (by OpenCode, git, etc.)
        -- This works together with autoread option to automatically reload buffers
        local autoread_group = vim.api.nvim_create_augroup("autoread", { clear = true })
        
        -- Check for file changes when entering a buffer or gaining focus
        vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter", "CursorHold" }, {
          group = autoread_group,
          pattern = "*",
          callback = function()
            -- Only check if the buffer is a normal file and is loaded
            if vim.bo.buftype == "" and vim.fn.getcmdwintype() == "" then
              vim.cmd("checktime")
            end
          end,
        })
        
        -- Suppress the "file changed" prompt and reload automatically
        vim.api.nvim_create_autocmd("FileChangedShellPost", {
          group = autoread_group,
          pattern = "*",
          callback = function()
            vim.notify("File reloaded: " .. vim.fn.expand("%"), vim.log.levels.INFO)
          end,
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
        {
          action = "<cmd>lua require('conform').format()<CR>";
          key = "<leader>bf";
          options.desc = "Buffer format";
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
        {
          action = "<cmd>Git diff<CR>";
          key = "<leader>gd";
          options.desc = "Git diff";
        }
        {
          action = "<cmd>Git log<CR>";
          key = "<leader>gl";
          options.desc = "Git log";
        }
        {
          action = "<cmd>Git commit<CR>";
          key = "<leader>gc";
          options.desc = "Git commit";
        }
        {
          action = "<cmd>Git pull<CR>";
          key = "<leader>gp";
          options.desc = "Git pull";
        }
        {
          action = "<cmd>Git push<CR>";
          key = "<leader>gP";
          options.desc = "Git push";
        }

        # Gitsigns (hunk operations)
        {
          action = "<cmd>Gitsigns preview_hunk<CR>";
          key = "<leader>gh";
          options.desc = "Preview git hunk";
        }
        {
          action = "<cmd>Gitsigns next_hunk<CR>";
          key = "<leader>gn";
          options.desc = "Next git hunk";
        }
        {
          action = "<cmd>Gitsigns prev_hunk<CR>";
          key = "<leader>gN";
          options.desc = "Previous git hunk";
        }
        {
          action = "<cmd>Gitsigns stage_hunk<CR>";
          key = "<leader>gs";
          mode = [ "n" "x" ];
          options.desc = "Stage git hunk";
        }
        {
          action = "<cmd>Gitsigns undo_stage_hunk<CR>";
          key = "<leader>gu";
          options.desc = "Unstage git hunk";
        }
        {
          action = "<cmd>Gitsigns reset_hunk<CR>";
          key = "<leader>gr";
          mode = [ "n" "x" ];
          options.desc = "Reset git hunk";
        }

        # LSP
        {
          action = "<cmd>LspInfo<CR>";
          key = "<leader>li";
          options.desc = "LSP Info";
        }
        {
          # Shows function signatures, types, and documentation in a float window
          # TODO: Experiment with auto-hover on CursorHold after getting used to manual trigger
          action = "<cmd>lua vim.lsp.buf.hover()<CR>";
          key = "<leader>lh";
          options.desc = "LSP Hover documentation";
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
          key = "<leader>lR";
          options.desc = "LSP Rename symbol";
        }
        {
          action = "<cmd>lua vim.lsp.buf.format()<CR>";
          key = "<leader>lf";
          options.desc = "LSP Format buffer";
        }
        {
          action = "<cmd>lua vim.lsp.buf.code_action()<CR>";
          key = "<leader>la";
          mode = [ "n" "x" ];
          options.desc = "LSP Code actions";
        }
        {
          action = "<cmd>lua vim.diagnostic.open_float()<CR>";
          key = "<leader>lm";
          options.desc = "LSP Show diagnostic message";
        }
        {
          action = "<cmd>Trouble diagnostics toggle<CR>";
          key = "<leader>le";
          options.desc = "Toggle diagnostics (Trouble)";
        }
        {
          action = "<cmd>Trouble diagnostics toggle filter.buf=0<CR>";
          key = "<leader>lb";
          options.desc = "Buffer diagnostics (Trouble)";
        }
        {
          action = "<cmd>lua vim.diagnostic.goto_next()<CR>";
          key = "<leader>ln";
          options.desc = "Next diagnostic";
        }
        {
          action = "<cmd>lua vim.diagnostic.goto_prev()<CR>";
          key = "<leader>lp";
          options.desc = "Previous diagnostic";
        }

        # Quickfix navigation
        {
          action = "<cmd>cnext<CR>";
          key = "<leader>qn";
          options.desc = "Next quickfix item";
        }
        {
          action = "<cmd>cprev<CR>";
          key = "<leader>qp";
          options.desc = "Previous quickfix item";
        }
        {
          action = "<cmd>Trouble qflist toggle<CR>";
          key = "<leader>qo";
          options.desc = "Open quickfix (Trouble)";
        }
        {
          action = "<cmd>Trouble close<CR>";
          key = "<leader>qc";
          options.desc = "Close Trouble";
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
          action = "<cmd>lua Snacks.picker.grep_word()<CR>";
          key = "<leader>fw";
          options.desc = "Grep word under cursor";
        }
        {
          action = "<cmd>lua Snacks.picker.lines()<CR>";
          key = "<leader>f/";
          options.desc = "Search in current buffer";
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
        cursorline = true;
        expandtab = true;
        ignorecase = true;
        inccommand = "split";
        incsearch = true;
        number = true;
        relativenumber = true;
        scrolloff = 8;
        shiftwidth = 2;
        sidescrolloff = 8;
        signcolumn = "yes:1";
        smartcase = true;
        swapfile = false;
        tabstop = 2;
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
              go = [ "gofmt" ];
              html = [ "prettier" ];
              json = [ "prettier" ];
              lua = [ "stylua" ];
              markdown = [ "prettier" ];
              nix = [ "alejandra" ];
              python = [ "isort" "black" ];
              rust = [ "rustfmt" ];
              sh = [ "shfmt" ];
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
        gitsigns = {
          enable = true;
          settings = {
            current_line_blame = false;
            signs = {
              add.text = "│";
              change.text = "│";
              delete.text = "_";
              topdelete.text = "‾";
              changedelete.text = "~";
              untracked.text = "┆";
            };
          };
        };
        lualine.enable = true;

        lsp = {
          enable = true;
          servers = {
            bashls.enable = true;
            cssls.enable = true;
            gopls.enable = true;
            html.enable = true;
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
            rust_analyzer = {
              enable = true;
              installCargo = true;
              installRustc = true;
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
          folding.enable = false;
          settings.indent.enable = true;
        };
        treesitter-textobjects = {
          enable = true;
          select = {
            enable = true;
            lookahead = true;
            keymaps = {
              # Usage examples:
              # vaf - select around function (including signature)
              # vif - select inside function (body only)
              # daf - delete entire function
              # yif - yank function body
              # cac - change entire class
              "af" = "@function.outer";
              "if" = "@function.inner";
              "ac" = "@class.outer";
              "ic" = "@class.inner";
              "aa" = "@parameter.outer";
              "ia" = "@parameter.inner";
              "al" = "@loop.outer";
              "il" = "@loop.inner";
              "ai" = "@conditional.outer";
              "ii" = "@conditional.inner";
            };
          };
        };
        trouble = {
          enable = true;
          settings = {
            auto_close = false;
            auto_open = false;
            use_diagnostic_signs = true;
          };
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

in
{
  options.mine.home.nixvim = {
    enable = lib.mkEnableOption "enable nixvim in home-manager";

    enableSopsSecrets = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to configure sops secrets for AI API keys (disable for work machines)";
    };
  };

  config = lib.mkIf cfg.enable (
    if isNixOS then {
      # NixOS mode: configure via home-manager.users wrapper
      # sops.secrets only works in NixOS context
      sops.secrets = lib.mkIf cfg.enableSopsSecrets {
        "BEDROCK_KEYS" = {
          owner = userConfig.username;
        };
        "OPENROUTER_API_KEY" = {
          owner = userConfig.username;
        };
      };

      home-manager.users.${userConfig.username} = lib.mkMerge [
        {
          home.packages = nixvimPackages;
          home.file = lib.mkIf cfg.enableSopsSecrets {
            ".config/fish/conf.d/90-vim-sops-secrets.fish" = {
              text = builtins.readFile ./setVimSessionVars.fish;
              executable = true;
            };
          };
        }
        nixvimConfig
      ];
    } else
    # Standalone home-manager mode: configure directly
    # Note: sops secrets not available in standalone mode
      lib.mkMerge [
        { home.packages = nixvimPackages; }
        nixvimConfig
      ]
  );
}
