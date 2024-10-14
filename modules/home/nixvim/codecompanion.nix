{ lib, pkgs, ... }:
let
  inherit (lib) mkIf;

  pname = "codecompanion";
  version = "v8.3.1";

  codecompanion_enable = true;
in
{
  home-manager.users.r6t.programs.nixvim.extraPlugins = with pkgs.vimUtils; [
    (buildVimPlugin {
      inherit pname version;
      src = pkgs.fetchFromGitHub {
        owner = "olimorris";
        repo = "codecompanion.nvim";
        rev = "refs/tags/${version}";
        hash = "sha256-2uTdh1TdXvIEosjf90caApR/tNNX5xJJKTgfCCEnDjs=";
      };
    })
  ];

  home-manager.users.r6t.programs.nixvim.plugins = {
	  dressing.enable = true;
	};
  home-manager.users.r6t.programs.nixvim.extraConfigLua = ''
    require("codecompanion").setup({
      adapters = {
          opts = {
            allow_insecure = true,
          },
          ollama = function()
            return require("codecompanion.adapters").extend("ollama", {
	      schema = {
                model = {
                  default = "deepseek-coder-v2:16b",
                },
              },
              env = {
                url = "http://silvertorch.magic.internal:11434",
              },
              headers = {
                ["Content-Type"] = "application/json",
              },
              parameters = {
                sync = true,
              },
            })
          end,
        },
       strategies = {
         chat = {
           adapter = "ollama",
         },
         inline = {
           adapter = "ollama",
         },
         agent = {
           adapter = "ollama",
         },
       },
      }
    );
    '';
  home-manager.users.r6t.programs.nixvim.keymaps = mkIf codecompanion_enable [
    {
      mode = [
        "n"
	"v"
      ];
      key = "<C-a>";
      action = "<Cmd>CodeCompanionActions<CR>";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      mode = [
        "n"
	"v"
      ];
      key = "<leader>ac";
      action = "<Cmd>CodeCompanionChat Toggle<CR>";
      options = {
        noremap = true;
        silent = true;
      };
    }
    {
      mode = "v";
      key = "<leader>aa";
      action = "<Cmd>CodeCompanionChat Add<CR>";
      options = {
        noremap = true;
        silent = true;
      };
    }
  ];

  home-manager.users.r6t.programs.nixvim.extraConfigVim = ''
    cabbrev cc CodeCompanion
   '';
}

