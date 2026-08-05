{ lib, ... }:

{
  options.mine.home.nixvim = {
    enable = lib.mkEnableOption "enable nixvim in home-manager";

    enableSopsSecrets = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to configure sops secrets for AI API keys";
    };

    enableHaMcp = lib.mkEnableOption "Home Assistant MCP server for OpenCode (requires HA_MCP_TOKEN sops secret)";

    opencode-llamacpp = {
      enable = lib.mkEnableOption "connect OpenCode to a local llama-server (llama.cpp) instance";

      baseURL = lib.mkOption {
        type = lib.types.str;
        default = "http://127.0.0.1:8080/v1";
        description = "llama-server OpenAI-compatible API endpoint.";
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
            variants = lib.mkOption {
              type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
              default = { };
              description = ''
                Per-model variants. Each key is a variant name (selectable in
                opencode via the `variant_cycle` keybind), each value is an
                attrset of options merged into the model's `options` when that
                variant is active. For OpenAI-compatible providers, opencode
                spreads these keys directly into the request body — so this is
                the place to set llama-server-specific extras like
                `chat_template_kwargs = { enable_thinking = true; }` to enable
                Qwen3 thinking mode for one variant while leaving the server
                default (`--reasoning off`) for the others.
              '';
              example = lib.literalExpression ''
                {
                  thinking.chat_template_kwargs = { enable_thinking = true; };
                }
              '';
            };
          };
        });
        default = { };
        description = "llama-server models to expose to OpenCode. Keys are model aliases (must match llama-server --alias or model name).";
      };
    };
  };
}
