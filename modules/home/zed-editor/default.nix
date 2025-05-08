{ lib, config, userConfig, ... }: {
  options = {
    mine.home.zed-editor.enable =
      lib.mkEnableOption "enable zed in home-manager";
  };

  config = lib.mkIf config.mine.home.zed-editor.enable {
    home-manager.users.${userConfig.username} = {
      # ollama proxy workaround while zed requires local ollama
      # home.packages = [ pkgs.socat ];
      # systemd.user.services.ollama-proxy = {
      #   Unit = {
      #     Description = "Ollama API Proxy";
      #     After = "network.target";
      #   };
      #   Service = {
      #     ExecStart = "${pkgs.socat}/bin/socat TCP-LISTEN:11434,reuseaddr,fork TCP:moon.magic.internal:11434";
      #     Restart = "always";
      #   };
      #   Install = {
      #     WantedBy = [ "default.target" ];
      #   };
      # };

      programs.zed-editor = {
        enable = true;
        extensions = [
          "nix"
          "toml"
          "lua"
          "python"
          "markdown"
        ];

        userSettings = {
          # LLM
          language_models = {
            ollama = {
              api_url = "http://moon.magic.internal:11434";
              available_models = [
                {
                  name = "deepseek-r1:14b";
                  display_name = "deepseek-r1:14b";
                  max_tokens = 32768;
                }
              ];
            };
          };
          assistant = {
            enabled = true;
            version = "2";
            default_model = {
              provider = "ollama";
              model = "deepseek-r1:14b";
              parameters = {
                temperature = 0.8;
                top_k = 40;
                top_p = 0.7;
                repeat_penalty = 1.1;
                num_ctx = 16384;
                stream = true;
              };
            };
          };
          # Vim mode similar to your nixvim config
          vim_mode = true;
          vim = {
            enable_vim_sneak = true;
          };

          # UI settings
          theme = "Oxocarbon Dark (Variation III)";
          relative_line_numbers = true;
          ui_font_size = 14;
          buffer_font_size = 14;
          tab_size = 2; # Based on your shiftwidth

          auto_update = false;
        };
      };
    };
  };
}
