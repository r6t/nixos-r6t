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

    modelFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Path to a GGUF model file to load eagerly at startup.
        When set, passed as --model to llama-server. The model is loaded
        immediately on service start, eliminating cold-start latency on
        the first request. Use this for single-model dedicated setups.
        Mutually exclusive with modelsPreset router mode.
      '';
      example = "/var/lib/llama-cpp/models/Qwen3-14B-Q6_K.gguf";
    };

    hfRepo = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        HuggingFace repository to auto-download the model from if modelFile
        does not exist on disk yet. Combined with hfFile. Once downloaded,
        the file is cached at modelsDir and loaded from there on subsequent starts.
      '';
      example = "unsloth/Qwen3-14B-GGUF";
    };

    hfFile = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        HuggingFace filename to download. Used with hfRepo.
      '';
      example = "Qwen3-14B-Q6_K.gguf";
    };

    modelsDir = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = ''
        Directory where GGUF model files are stored. Used as the storage
        location for HuggingFace auto-downloads. All models accumulate here
        across container rebuilds via the persistent bind-mount.
        When set, passed as --models-dir to llama-server.
      '';
    };

    modelsPreset = lib.mkOption {
      type = lib.types.nullOr (lib.types.attrsOf (lib.types.attrsOf lib.types.str));
      default = null;
      description = ''
        Declarative model preset configuration for the llama-server router mode.
        Each key is a model alias, with attrs for hf-repo, hf-file, etc.
        Models are loaded on-demand (cold start on first request per model).
        Use modelFile instead for eager single-model loading.
      '';
      example = lib.literalExpression ''
        {
          "qwen3-14b" = {
            hf-repo = "unsloth/Qwen3-14B-GGUF";
            hf-file = "Qwen3-14B-Q6_K.gguf";
            alias = "qwen3-14b";
          };
        }
      '';
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 65536;
      description = ''
        Context window size in tokens passed as -c to llama-server.
        Override per model when VRAM headroom requires a smaller context
        (e.g. 32768 for larger 24B models at 4-bit quant on 16 GiB).
      '';
    };

    extraFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Additional CLI flags appended to the base llama-server flags.
        The base flags (GPU offload, flash-attn, KV quant, context, priority,
        cache-reuse, parallel slots) are always applied. Use this for
        model-specific flags like --jinja.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    services.llama-cpp = {
      enable = true;
      inherit (cfg) host port modelsPreset;
      extraFlags = [
        # GPU offload: push all transformer layers to VRAM
        "-ngl"
        "99"
        # Flash attention: fix for CUDA buffer overlap crash on RTX 5060 Ti
        # (compute 12.0), landed in llama.cpp de1aa6fa, nixpkgs b8733+.
        "--flash-attn"
        "auto"
        # KV cache quantization: q8_0 halves KV cache VRAM vs f16.
        "--cache-type-k"
        "q8_0"
        "--cache-type-v"
        "q8_0"
        # Context window — override via contextSize option.
        "-c"
        (toString cfg.contextSize)
        # Physical micro-batch: faster prefill on long prompts.
        "-ub"
        "2048"
        # High process priority — GPU is dedicated to LLM inference.
        "--prio"
        "2"
        # KV prefix reuse across requests (system prompt caching).
        "--cache-reuse"
        "256"
        # Single parallel slot — all VRAM to one session.
        "-np"
        "1"
      ]
      ++ cfg.extraFlags
      ++ lib.optionals (cfg.modelFile != null) [ "--model" cfg.modelFile ]
      ++ lib.optionals (cfg.modelsDir != null) [ "--models-dir" cfg.modelsDir ]
      ++ lib.optionals (cfg.hfRepo != null) [ "--hf-repo" cfg.hfRepo ]
      ++ lib.optionals (cfg.hfFile != null) [ "--hf-file" cfg.hfFile ];
      openFirewall = true;
    };
  };
}
