{ lib, config, pkgs, userConfig, isNixOS ? true, ... }:

let
  cfg = config.mine.home.nixvim;
  wrapHome = import ../../lib/mkPortableHomeConfig.nix { inherit isNixOS userConfig; };
  c = (import ../../lib/palette.nix).hex;
  ollamaCfg = cfg.opencode-ollama;

  # Build the opencode.json Ollama provider config when enabled
  opencodeOllamaConfig = lib.mkIf ollamaCfg.enable {
    ".config/opencode/opencode.json" = {
      text = builtins.toJSON (
        {
          "$schema" = "https://opencode.ai/config.json";
        }
        // lib.optionalAttrs cfg.enableHaMcp {
          mcp = {
            homeassistant = {
              type = "remote";
              url = "https://homeassistant.r6t.io/api/mcp";
              enabled = true;
              oauth = false;
              headers = {
                Authorization = "Bearer {env:HA_MCP_TOKEN}";
              };
            };
          };
        }
        // {
          provider = {
            ollama = {
              npm = "@ai-sdk/openai-compatible";
              name = "Ollama (local)";
              options = {
                inherit (ollamaCfg) baseURL;
              };
              models = lib.mapAttrs
                (_id: m:
                  {
                    inherit (m) name;
                  }
                  // lib.optionalAttrs (m.context != null || m.output != null) {
                    limit =
                      lib.optionalAttrs (m.context != null) { inherit (m) context; }
                      // lib.optionalAttrs (m.output != null) { inherit (m) output; };
                  }
                )
                ollamaCfg.models;
            };
          };
        }
      );
    };
  };

  # Opencode oxocarbon theme + tui config
  # Theme file goes to ~/.config/opencode/themes/oxocarbon.json
  # tui.json goes to ~/.config/opencode/tui.json
  opencodeThemeConfig = {
    ".config/opencode/themes/oxocarbon.json" = {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/theme.json";
        defs = {
          # Oxocarbon dark palette — from modules/lib/palette.nix
          inherit (c) base00 base01 base02 base03 base04 base05
            teal cyan blue pink lightpink green violet lightblue;
          inherit (c) coolGray darkblue;
        };
        theme = {
          # agent color cycle: [secondary, accent, success, warning, primary, error, info]
          # build=secondary(green), plan=accent(teal), then success/warning/primary/...
          primary = { dark = "blue"; light = "blue"; };
          secondary = { dark = "green"; light = "green"; };
          accent = { dark = "teal"; light = "teal"; };
          error = { dark = "pink"; light = "pink"; };
          warning = { dark = "lightpink"; light = "lightpink"; };
          success = { dark = "green"; light = "green"; };
          info = { dark = "violet"; light = "violet"; };
          text = { dark = "base04"; light = "base00"; };
          textMuted = { dark = "coolGray"; light = "base03"; };
          background = { dark = "base00"; light = "base05"; };
          backgroundPanel = { dark = "base01"; light = "base04"; };
          backgroundElement = { dark = "base02"; light = "base04"; };
          border = { dark = "base02"; light = "base03"; };
          borderActive = { dark = "teal"; light = "teal"; };
          borderSubtle = { dark = "base01"; light = "base04"; };
          diffAdded = { dark = "green"; light = "green"; };
          diffRemoved = { dark = "pink"; light = "pink"; };
          diffContext = { dark = "base03"; light = "base03"; };
          diffHunkHeader = { dark = "base03"; light = "base03"; };
          diffHighlightAdded = { dark = "green"; light = "green"; };
          diffHighlightRemoved = { dark = "pink"; light = "pink"; };
          diffAddedBg = { dark = "base01"; light = "base04"; };
          diffRemovedBg = { dark = "base01"; light = "base04"; };
          diffContextBg = { dark = "base00"; light = "base05"; };
          diffLineNumber = { dark = "base03"; light = "base03"; };
          diffAddedLineNumberBg = { dark = "base01"; light = "base04"; };
          diffRemovedLineNumberBg = { dark = "base01"; light = "base04"; };
          markdownText = { dark = "base05"; light = "base00"; };
          markdownHeading = { dark = "teal"; light = "teal"; };
          markdownLink = { dark = "blue"; light = "blue"; };
          markdownLinkText = { dark = "cyan"; light = "cyan"; };
          markdownCode = { dark = "green"; light = "green"; };
          markdownBlockQuote = { dark = "base03"; light = "base03"; };
          markdownEmph = { dark = "lightpink"; light = "lightpink"; };
          markdownStrong = { dark = "lightblue"; light = "lightblue"; };
          markdownHorizontalRule = { dark = "base02"; light = "base02"; };
          markdownListItem = { dark = "teal"; light = "teal"; };
          markdownListEnumeration = { dark = "cyan"; light = "cyan"; };
          markdownImage = { dark = "blue"; light = "blue"; };
          markdownImageText = { dark = "cyan"; light = "cyan"; };
          markdownCodeBlock = { dark = "base04"; light = "base01"; };
          syntaxComment = { dark = "base03"; light = "base03"; };
          syntaxKeyword = { dark = "blue"; light = "blue"; };
          syntaxFunction = { dark = "lightpink"; light = "lightpink"; };
          syntaxVariable = { dark = "base04"; light = "base01"; };
          syntaxString = { dark = "green"; light = "green"; };
          syntaxNumber = { dark = "lightblue"; light = "lightblue"; };
          syntaxType = { dark = "violet"; light = "violet"; };
          syntaxOperator = { dark = "blue"; light = "blue"; };
          syntaxPunctuation = { dark = "cyan"; light = "cyan"; };
        };
      };
    };
    ".config/opencode/tui.json" = {
      text = builtins.toJSON {
        "$schema" = "https://opencode.ai/tui.json";
        theme = "oxocarbon";
      };
    };
  };

  # Shared packages
  nixvimPackages = with pkgs; [
    # formatters
    python3Packages.black
    python3Packages.isort
    prettier
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
        # Zellij-aware pane/split navigation (Ctrl+hjkl)
        # From nvim: moves between nvim splits, crosses into zellij panes at edges
        # From fish panes: use Alt+hjkl instead (zellij native)
        {
          action = "<cmd>ZellijNavigateLeft<CR>";
          key = "<C-h>";
          options.desc = "Navigate left (nvim split or zellij pane)";
        }
        {
          action = "<cmd>ZellijNavigateDown<CR>";
          key = "<C-j>";
          options.desc = "Navigate down (nvim split or zellij pane)";
        }
        {
          action = "<cmd>ZellijNavigateUp<CR>";
          key = "<C-k>";
          options.desc = "Navigate up (nvim split or zellij pane)";
        }
        {
          action = "<cmd>ZellijNavigateRight<CR>";
          key = "<C-l>";
          options.desc = "Navigate right (nvim split or zellij pane)";
        }

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
          action = "<cmd>Git add -p<CR>";
          key = "<leader>ga";
          options.desc = "Git add by hunk";
        }
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
        {
          action = "<cmd>Git fetch<CR>";
          key = "<leader>gf";
          options.desc = "Git fetch";
        }
        {
          action = "<cmd>Git rebase -i HEAD~10<CR>";
          key = "<leader>gri";
          options.desc = "Git rebase interactive (last 10)";
        }
        {
          action = "<cmd>Git rebase --continue<CR>";
          key = "<leader>grc";
          options.desc = "Git rebase continue";
        }
        {
          action = "<cmd>Git rebase --abort<CR>";
          key = "<leader>gra";
          options.desc = "Git rebase abort";
        }
        {
          action = "<cmd>Git rebase --skip<CR>";
          key = "<leader>grs";
          options.desc = "Git rebase skip";
        }
        {
          action = "<cmd>Git merge<CR>";
          key = "<leader>gm";
          options.desc = "Git merge";
        }
        {
          action = "<cmd>Git merge --abort<CR>";
          key = "<leader>gma";
          options.desc = "Git merge abort";
        }
        {
          # Gdiffsplit! = 3-way diff for conflict resolution
          # left=//2 target/ours, middle=working copy, right=//3 merge/theirs
          action = "<cmd>Gdiffsplit!<CR>";
          key = "<leader>gdd";
          options.desc = "3-way diff (conflict resolution)";
        }
        {
          # In 3-way diff: pull hunk from target/ours (left pane)
          action = "<cmd>diffget //2<CR>";
          key = "<leader>g2";
          options.desc = "Diffget from target/ours (//2)";
        }
        {
          # In 3-way diff: pull hunk from merge/theirs (right pane)
          action = "<cmd>diffget //3<CR>";
          key = "<leader>g3";
          options.desc = "Diffget from merge/theirs (//3)";
        }
        {
          action = "<cmd>Git stash<CR>";
          key = "<leader>gSs";
          options.desc = "Git stash";
        }
        {
          action = "<cmd>Git stash pop<CR>";
          key = "<leader>gSp";
          options.desc = "Git stash pop";
        }
        {
          action = "<cmd>Git stash list<CR>";
          key = "<leader>gSl";
          options.desc = "Git stash list";
        }
        {
          action = "<cmd>Git cherry-pick<CR>";
          key = "<leader>go";
          options.desc = "Git cherry-pick";
        }
        {
          action = "<cmd>Gwrite<CR>";
          key = "<leader>gw";
          options.desc = "Gwrite: stage/checkout current file";
        }
        {
          action = "<cmd>Gread<CR>";
          key = "<leader>gR";
          options.desc = "Gread: revert buffer to index";
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
          settings = {
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
      default = false;
      description = "Whether to configure sops secrets for AI API keys";
    };

    enableHaMcp = lib.mkEnableOption "Home Assistant MCP server for OpenCode (requires HA_MCP_TOKEN sops secret)";

    opencode-ollama = {
      enable = lib.mkEnableOption "connect OpenCode to a local/remote Ollama instance";

      baseURL = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:11434/v1";
        description = "Ollama OpenAI-compatible API endpoint.";
      };

      models = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            name = lib.mkOption {
              type = lib.types.str;
              description = "Display name shown in OpenCode model picker.";
            };
            context = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Max input context tokens (null = provider default).";
            };
            output = lib.mkOption {
              type = lib.types.nullOr lib.types.int;
              default = null;
              description = "Max output tokens (null = provider default).";
            };
          };
        });
        default = { };
        description = "Ollama models to expose to OpenCode. Keys are Ollama model IDs.";
      };
    };
  };

  config = lib.mkIf cfg.enable (
    let
      hmConfig = lib.mkMerge [
        {
          home.packages = nixvimPackages;
          home.file = lib.mkMerge (
            lib.optional (isNixOS && cfg.enableSopsSecrets)
              {
                ".config/fish/conf.d/90-vim-sops-secrets.fish" = {
                  text = builtins.readFile ./setVimSessionVars.fish;
                  executable = true;
                };
              }
            ++ [ opencodeOllamaConfig opencodeThemeConfig ]
          );
        }
        nixvimConfig
      ];
    in
    wrapHome hmConfig // lib.optionalAttrs isNixOS {
      # sops.secrets only works in NixOS context
      sops.secrets = lib.mkIf cfg.enableSopsSecrets (
        {
          "BEDROCK_KEYS" = { owner = userConfig.username; };
          "OPENROUTER_API_KEY" = { owner = userConfig.username; };
        }
        // lib.optionalAttrs cfg.enableHaMcp {
          "HA_MCP_TOKEN" = { owner = userConfig.username; };
        }
      );
    }
  );
}
