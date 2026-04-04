{ lib, config, ... }:
let
  cfg = config.mine.llama-cpp;
in
{

  options.mine.llama-cpp = {
    enable = lib.mkEnableOption "llama.cpp inference server (llama-server)";

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Address for llama-server to listen on.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8080;
      description = "Port for llama-server to listen on.";
    };

    modelsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Directory containing GGUF model files.
        When set, passed as --model-store to llama-server.
      '';
    };

    modelsPreset = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf (lib.types.attrsOf lib.types.str));
      default = null;
      description = ''
        Declarative model preset configuration for HuggingFace auto-download.
        Each key is a model alias, with attrs for hf-repo, hf-file, etc.
        Passed to services.llama-cpp.modelsPreset.
      '';
      example = lib.literalExpression ''
        {
          "qwen3-14b" = {
            hf-repo = "Qwen/Qwen3-14B-GGUF";
            hf-file = "qwen3-14b-q8_0.gguf";
            alias = "qwen3-14b";
          };
        }
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "-ngl"
        "99"
        "--flash-attn"
        "on"
        "--cache-type-k"
        "q8_0"
        "--cache-type-v"
        "q8_0"
      ];
      description = ''
        Extra CLI flags passed to llama-server.
        Defaults enable full GPU offload, flash attention,
        and quantized KV cache for reduced VRAM usage.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.llama-cpp = {
      enable = true;
      inherit (cfg) host port extraFlags modelsDir modelsPreset;
      openFirewall = true;
    };
  };
}
